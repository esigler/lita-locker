# Locker subsystem
module Locker
  # Misc helpers
  module Misc
    def user_locks(user)
      owned = []
      labels.each do |name|
        label = label(name)
        owned.push(name) if label.owner_id.value == user.id
      end
      owned
    end
  end
end
