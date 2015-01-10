# Locker subsystem
module Locker
  # Resource helpers
  module Resource
    # Proper Resource class
    class Resource
      include Redis::Objects

      value :state
      value :owner_id

      lock :coord, expiration: 5

      attr_reader :id

      def initialize(key)
        fail 'Unknown resource key' unless Resource.exists?(key)
        @id = key
      end

      def self.exists?(key)
        redis.sismember('resource-list', key)
      end

      def self.create(key)
        fail 'Resource key already exists' if Resource.exists?(key)
        redis.sadd('resource-list', key)
        r = Resource.new(key)
        r.state    = 'unlocked'
        r.owner_id = ''
        r
      end

      def self.delete(key)
        fail 'Unknown resource key' unless Resource.exists?(key)
        # FIXME: Better way to enumerate?
        %w(name, state, owner_id).each do |item|
          redis.del("resource:#{key}:#{item}")
        end
        redis.srem('resource-list', key)
      end

      def self.list
        redis.smembers('resource-list').sort
      end

      def lock!(owner_id)
        return false if state == 'locked'
        coord_lock.lock do
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
        end
        true
      end

      def locked?
        (state == 'locked')
      end

      def owner
        return nil unless locked?
        Lita::User.find_by_id(owner_id.value)
      end

      def to_json
        {
          id: id,
          state: state.value,
          owner_id: owner_id.value
        }.to_json
      end
    end
  end
end
