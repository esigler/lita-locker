# Locker subsystem
module Locker
  # Resource helpers
  module Resource
    def resource(name)
      redis.hgetall("resource_#{name}")
    end

    def resources
      redis.keys('resource_*')
    end

    def resource_exists?(name)
      redis.exists("resource_#{name}")
    end

    def lock_resource!(name, owner, time_until)
      return false unless resource_exists?(name)
      resource_key = "resource_#{name}"
      value = redis.hget(resource_key, 'state')
      return false unless value == 'unlocked'
      # FIXME: Race condition!
      redis.hset(resource_key, 'state', 'locked')
      redis.hset(resource_key, 'owner_id', owner.id)
      redis.hset(resource_key, 'until', time_until)
      true
    end

    def unlock_resource!(name)
      return false unless resource_exists?(name)
      key = "resource_#{name}"
      redis.hset(key, 'state', 'unlocked')
      redis.hset(key, 'owner_id', '')
      true
    end

    def create_resource(name)
      resource_key = "resource_#{name}"
      redis.hset(resource_key, 'state', 'unlocked') unless
        resource_exists?(name) || label_exists?(name)
    end

    def delete_resource(name)
      resource_key = "resource_#{name}"
      redis.del(resource_key) if resource_exists?(name)
    end
  end
end
