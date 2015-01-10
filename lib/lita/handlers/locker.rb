module Lita
  # Handy, isn't it?
  module Handlers
    # Top-level class for Locker
    class Locker < Handler
      Redis::Objects.redis = Lita.redis

      include ::Locker::Label
      include ::Locker::Misc
      include ::Locker::Regex
      include ::Locker::Resource

      route(
        /^#{LOCK_REGEX}#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :lock
      )

      route(
        /^#{UNLOCK_REGEX}#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :unlock
      )

      route(
        /^lock\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :lock,
        command: true,
        help: { t('help.lock.syntax') => t('help.lock.desc') }
      )

      route(
        /^unlock\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :unlock,
        command: true,
        help: { t('help.unlock.syntax') => t('help.unlock.desc') }
      )

      route(
        /^steal\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :steal,
        command: true,
        help: { t('help.steal.syntax') => t('help.steal.desc') }
      )

      def lock(response)
        name = response.match_data['label']

        return response.reply(t('label.does_not_exist', name: name)) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.no_resources', name: name)) unless l.membership.count > 0
        return response.reply(t('label.self_lock', name: name)) if l.owner == response.user
        return response.reply(t('label.lock', name: name)) if l.lock!(response.user.id)

        response.reply(label_ownership(name))
      end

      def unlock(response)
        name = response.match_data['label']
        return response.reply(t('subject.does_not_exist', name: name)) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.is_unlocked', name: name)) unless l.locked?
        response.reply(attempt_unlock(name, response.user))
      end

      def steal(response)
        name = response.match_data['label']
        return response.reply(t('subject.does_not_exist', name: name)) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('steal.already_unlocked', label: name)) unless l.locked?
        response.reply(attempt_steal(name, response.user))
      end

      private

      def attempt_steal(name, user)
        label = Label.new(name)
        return t('steal.self') if label.owner == user
        old_owner = label.owner
        label.steal!(user.id)
        mention = old_owner.mention_name ? "(@#{old_owner.mention_name})" : ''
        t('steal.stolen', label: name, old_owner: old_owner.name, mention: mention)
      end

      def attempt_unlock(name, user)
        label = Label.new(name)
        if label.owner == user
          label.unlock!
          if label.locked?
            mention = label.owner.mention_name ? "(@#{label.owner.mention_name})" : ''
            t('label.now_locked_by', name: name, owner: label.owner.name, mention: mention)
          else
            t('label.unlock', name: name)
          end
        else
          mention = label.owner.mention_name ? "(@#{label.owner.mention_name})" : ''
          t('label.owned_unlock', name: name, owner_name: label.owner.name, mention: mention)
        end
      end
    end

    Lita.register_handler(Locker)
  end
end
