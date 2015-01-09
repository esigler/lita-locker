# Locker subsystem
module Locker
  # Label helpers
  module Label
    # Proper Resource class
    class Label
      include Redis::Objects

      value :name
      value :state
      value :owner_id

      set :membership
      list :wait_queue

      lock :coord, expiration: 5

      attr_reader :id

      def initialize(key)
        fail 'Unknown label key' unless Label.exists?(key)
        @id = Label.normalize(key)
      end

      def self.exists?(key)
        redis.sismember('label-list', Label.normalize(key))
      end

      def self.create(key)
        fail 'Label key already exists' if Label.exists?(key)
        redis.sadd('label-list', Label.normalize(key))
        l = Label.new(key)
        l.state    = 'unlocked'
        l.owner_id = ''
        l
      end

      def self.delete(key)
        fail 'Unknown label key' unless Label.exists?(key)
        # FIXME: Better way to enumerate?
        %w(name, state, owner_id).each do |item|
          redis.del("label:#{key}:#{item}")
        end
        redis.srem('label-list', Label.normalize(key))
      end

      def self.list
        redis.smembers('label-list')
      end

      def self.normalize(key)
        key.strip.downcase
      end

      def lock!(owner_id)
        if locked?
          wait_queue << owner_id if wait_queue.last != owner_id
          return false
        end

        coord_lock.lock do
          membership.each do |resource_name|
            r = Locker::Resource::Resource.new(resource_name)
            # FIXME: Broken lock logic - partial locks would result in lockout
            return false unless r.lock!(owner_id)
          end
          self.owner_id = owner_id
          self.state = 'locked'
        end
        true
      end

      def unlock!
        return true if state == 'unlocked'
        coord_lock.lock do
          self.owner_id = ''
          self.state = 'unlocked'
          membership.each do |resource_name|
            r = Locker::Resource::Resource.new(resource_name)
            r.unlock!
          end
        end

        # FIXME: Possible race condition where resources become unavailable  between unlock and relock
        if wait_queue.count > 0
          next_user = wait_queue.shift
          self.lock!(next_user)
        end
        true
      end

      def steal!(owner_id)
        wait_queue.unshift(owner_id)
        self.unlock!
      end

      def locked?
        (state == 'locked')
      end

      def add_resource(resource)
        membership << resource.id
      end

      def remove_resource(resource)
        membership.delete(resource.id)
      end

      def owner
        return nil unless locked?
        Lita::User.find_by_id(owner_id)
      end
    end

    def label(name)
      Label.new(name)
    end

    def labels
      Label.list
    end

    def label_locked?(name)
      l = Label.new(name)
      l.locked?
    end

    def lock_label!(name, owner, _time_until)
      l = Label.new(name)
      l.lock!(owner.id)
    end

    def unlock_label!(name)
      l = Label.new(name)
      l.unlock!
    end

    def create_label(name)
      return false if Label.exists?(name)
      Label.create(name)
    end

    def delete_label(name)
      Label.delete(name) if Label.exists?(name)
    end

    def label_membership(name)
      l = Label.new(name)
      l.membership
    end

    def add_resource_to_label(label, resource)
      l = Label.new(label)
      r = resource(resource)
      l.add_resource(r)
    end

    def remove_resource_from_label(label, resource)
      l = Label.new(label)
      r = resource(resource)
      l.remove_resource(r)
    end

    def label_ownership(name)
      l = label(name)
      return label_dependencies(name) unless label_locked?(name)
      o = Lita::User.find_by_id(l.owner_id.value)
      mention = o.mention_name ? "(@#{o.mention_name})" : ''
      t('label.owned_lock', name: name, owner_name: o.name, mention: mention)
    end

    def label_dependencies(name)
      msg = t('label.dependency') + "\n"
      deps = []
      label_membership(name).each do |resource_name|
        resource = resource(resource_name)
        u = Lita::User.find_by_id(resource.owner_id.value)
        if resource.state.value == 'locked'
          deps.push "#{resource_name} - #{u.name}"
        end
      end
      msg += deps.join("\n")
      msg
    end
  end
end
