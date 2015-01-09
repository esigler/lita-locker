# Locker subsystem
module Locker
  # Misc helpers
  module Misc
    def user_locks(user)
      owned = []
      Locker::Label::Label.list.each do |name|
        label = Locker::Label::Label.new(name)
        owned.push(name) if label.owner_id.value == user.id
      end
      owned
    end
  end
end
