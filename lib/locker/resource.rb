# Locker subsystem
module Locker
  # Resource helpers
  module Resource
    # Proper Resource class
    class Resource
      include Redis::Objects

      value :name
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
        redis.smembers('resource-list')
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
    end

    def resource(name)
      Resource.new(name)
    end

    def resources
      Resource.list
    end

    def resource_exists?(name)
      Resource.exists?(name)
    end

    def lock_resource!(name, owner, _time_until)
      r = Resource.new(name)
      r.lock!(owner.id)
    end

    def unlock_resource!(name)
      r = Resource.new(name)
      r.unlock!
    end

    def create_resource(name)
      Resource.create(name)
    end

    def delete_resource(name)
      Resource.delete(name)
    end
  end
end
