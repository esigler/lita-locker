# Locker subsystem
module Locker
  # Label helpers
  module Label
    # Proper Resource class
    class Label
      include Redis::Objects

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
        redis.smembers('label-list').sort
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
        Lita::User.find_by_id(owner_id.value)
      end

      def to_json
        {
          id: id,
          state: state.value,
          owner_id: owner_id.value,
          membership: membership,
          wait_queue: wait_queue
        }.to_json
      end
    end

    def label_ownership(name)
      l = Label.new(name)
      return label_dependencies(name) unless l.locked?
      mention = l.owner.mention_name ? "(@#{l.owner.mention_name})" : ''
      t('label.owned_lock', name: name, owner_name: l.owner.name, mention: mention)
    end

    def label_dependencies(name)
      msg = t('label.dependency') + "\n"
      deps = []
      l = Label.new(name)
      l.membership.each do |resource_name|
        resource = Locker::Resource::Resource.new(resource_name)
        if resource.state.value == 'locked'
          deps.push "#{resource_name} - #{resource.owner.name}"
        end
      end
      msg += deps.join("\n")
      msg
    end
  end
end
