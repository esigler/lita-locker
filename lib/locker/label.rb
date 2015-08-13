# Locker subsystem
module Locker
  # Label helpers
  module Label
    # Proper Resource class
    class Label
      include Redis::Objects

      value :state
      value :owner_id
      value :taken_at

      set :membership
      set :observer_ids
      list :wait_queue
      list :journal

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
        l.log('Created')
        l
      end

      def self.delete(key)
        fail 'Unknown label key' unless Label.exists?(key)
        %w(state, owner_id, membership, wait_queue, journal, observer_ids).each do |item|
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
            return false if r.locked?
          end
          # TODO: read-modify-write cycle, not the best
          membership.each do |resource_name|
            r = Locker::Resource::Resource.new(resource_name)
            r.lock!(owner_id)
          end
          self.owner_id = owner_id
          self.state = 'locked'
          self.taken_at = Time.now.utc
        end
        u = Lita::User.fuzzy_find(owner_id)
        log("Locked by #{u.name}")
        true
      end

      def unlock!
        return true if state == 'unlocked'
        coord_lock.lock do
          self.owner_id = ''
          self.state = 'unlocked'
          self.taken_at = ''
          membership.each do |resource_name|
            r = Locker::Resource::Resource.new(resource_name)
            r.unlock!
          end
        end
        log('Unlocked')

        # FIXME: Possible race condition where resources become unavailable between unlock and relock
        if wait_queue.count > 0
          next_user = wait_queue.shift
          self.lock!(next_user)
        end
        true
      end

      def steal!(owner_id)
        log("Stolen from #{owner.id} to #{owner_id}")
        wait_queue.unshift(owner_id)
        self.dedupe!
        self.unlock!
      end

      def give!(recipient_id)
        log("Given from #{owner.id} to #{recipient_id}")
        wait_queue.unshift(recipient_id)
        self.dedupe!
        self.unlock!
      end

      def dedupe!
        queued = wait_queue.to_a
        wait_queue.clear
        queued.chunk { |x| x }.map(&:first).each do |user|
          wait_queue << user
        end
      end

      def add_observer!(observer_id)
        observer_ids.add(observer_id)
      end

      def remove_observer!(observer_id)
        observer_ids.delete(observer_id)
      end

      def observer?(observer_id)
        observer_ids.member?(observer_id)
      end

      def locked?
        (state == 'locked')
      end

      def observers
        observer_ids.map do |observer_id|
          Lita::User.find_by_id(observer_id)
        end
      end

      def add_resource(resource)
        log("Resource #{resource.id} added")
        resource.labels << id
        membership << resource.id
      end

      def remove_resource(resource)
        log("Resource #{resource.id} removed")
        resource.labels.delete(id)
        membership.delete(resource.id)
      end

      def owner
        return nil unless locked?
        Lita::User.find_by_id(owner_id.value)
      end

      def held_for
        return '' unless locked?
        TimeLord::Time.new(Time.parse(taken_at.value) - 1).period.to_words
      end

      def to_json
        val = { id: id,
                state: state.value,
                membership: membership }

        if locked?
          val[:owner_id] = owner_id.value
          val[:taken_at] = taken_at.value
          val[:wait_queue] = wait_queue
        end

        val.to_json
      end

      def log(statement)
        journal << "#{Time.now.utc}: #{statement}"
      end
    end

    def label_ownership(name)
      l = Label.new(name)
      return label_dependencies(name) unless l.locked?
      queue = []
      l.wait_queue.each do |u|
        usr = Lita::User.find_by_id(u)
        queue.push(usr.name)
      end
      mention = l.owner.mention_name ? "(@#{l.owner.mention_name})" : ''
      failed(t('label.owned_lock', name: name,
                                   owner_name: l.owner.name,
                                   mention: mention,
                                   time: l.held_for,
                                   queue: queue.join(', ')))
    end

    def label_dependencies(name)
      msg = failed(t('label.dependency')) + "\n"
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
