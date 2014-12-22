# Locker subsystem
module Locker
  # Label helpers
  module Label
    def label(name)
      redis.hgetall("label_#{name}")
    end

    def labels
      redis.keys('label_*')
    end

    def label_exists?(name)
      redis.exists("label_#{name}")
    end

    def label_locked?(name)
      l = label(name)
      l['state'] == 'locked'
    end

    def lock_label!(name, owner, time_until)
      return false unless label_exists?(name)
      key = "label_#{name}"
      members = label_membership(name)
      members.each do |m|
        return false unless lock_resource!(m, owner, time_until)
      end
      redis.hset(key, 'state', 'locked')
      redis.hset(key, 'owner_id', owner.id)
      redis.hset(key, 'until', time_until)
      true
    end

    def unlock_label!(name)
      return false unless label_exists?(name)
      key = "label_#{name}"
      members = label_membership(name)
      members.each do |m|
        unlock_resource!(m)
      end
      redis.hset(key, 'state', 'unlocked')
      redis.hset(key, 'owner_id', '')
      true
    end

    def create_label(name)
      label_key = "label_#{name}"
      redis.hset(label_key, 'state', 'unlocked') unless
        resource_exists?(name) || label_exists?(name)
    end

    def delete_label(name)
      label_key = "label_#{name}"
      redis.del(label_key) if label_exists?(name)
    end

    def label_membership(name)
      redis.smembers("membership_#{name}")
    end

    def add_resource_to_label(label, resource)
      return unless label_exists?(label) && resource_exists?(resource)
      redis.sadd("membership_#{label}", resource)
    end

    def remove_resource_from_label(label, resource)
      return unless label_exists?(label) && resource_exists?(resource)
      redis.srem("membership_#{label}", resource)
    end
  end
end
