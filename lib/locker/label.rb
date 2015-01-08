# Locker subsystem
module Locker
  # Label helpers
  module Label
    def label(name)
      redis.hgetall(normalize_label_key(name))
    end

    def labels
      redis.keys('label_*')
    end

    def label_exists?(name)
      redis.exists(normalize_label_key(name))
    end

    def label_locked?(name)
      l = label(name)
      l['state'] == 'locked'
    end

    def lock_label!(name, owner, time_until)
      return false unless label_exists?(name)
      key = normalize_label_key(name)
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
      key = normalize_label_key(name)
      members = label_membership(name)
      members.each do |m|
        unlock_resource!(m)
      end
      redis.hset(key, 'state', 'unlocked')
      redis.hset(key, 'owner_id', '')
      true
    end

    def create_label(name)
      label_key = normalize_label_key(name)
      redis.hset(label_key, 'state', 'unlocked') unless
        resource_exists?(name) || label_exists?(name)
    end

    def delete_label(name)
      label_key = normalize_label_key(name)
      redis.del(label_key) if label_exists?(name)
    end

    def label_membership(name)
      redis.smembers("membership_#{normalize_name(name)}")
    end

    def add_resource_to_label(label, resource)
      return unless label_exists?(label) && resource_exists?(resource)
      redis.sadd("membership_#{label}", resource)
    end

    def remove_resource_from_label(label, resource)
      return unless label_exists?(label) && resource_exists?(resource)
      redis.srem("membership_#{label}", resource)
    end

    def label_ownership(name)
      l = label(name)
      return label_dependencies(name) unless label_locked?(name)
      o = Lita::User.find_by_id(l['owner_id'])
      mention = o.mention_name ? "(@#{o.mention_name})" : ''
      t('label.owned', name: name, owner_name: o.name, mention: mention)
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

    def normalize_label_key(name)
      "label_#{normalize_name(name)}"
    end

    def normalize_name(name)
      name.strip
    end
  end
end
