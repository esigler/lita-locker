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

    def adapter
      if Lita.respond_to?(:config)
        Lita.config.robot.adapter
      elsif robot.respond_to?(:config)
        robot.config.robot.adapter
      else
        :unknown
      end
    end

    def failed(message)
      case adapter
      when :hipchat
        "(failed) #{message}"
      else
        message
      end
    end

    def locked(message)
      case adapter
      when :hipchat
        "(lock) #{message}"
      else
        message
      end
    end

    def unlocked(message)
      case adapter
      when :hipchat
        "(unlock) #{message}"
      else
        message
      end
    end
  end
end
