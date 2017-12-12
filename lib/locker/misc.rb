# frozen_string_literal: true

# Locker subsystem
module Locker
  # Misc helpers
  module Misc
    def user_locks(user)
      owned = []
      Locker::Label::Label.list.each do |name|
        label = Locker::Label::Label.new(name)
        owned.push(name) if label.owner == user
      end
      owned
    end

    def success(message)
      render_template('success', string: message)
    end

    def failed(message)
      render_template('failed', string: message)
    end

    def locked(message)
      render_template('lock', string: message)
    end

    def unlocked(message)
      render_template('unlock', string: message)
    end
  end
end
