module Lita
  # Handy, isn't it?
  module Handlers
    # Top-level class for Locker
    class Locker < Handler
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
        name = response.matches[0][0]

        return response.reply('(failed) ' + t('label.does_not_exist', name: name)) unless label_exists?(name)
        m = label_membership(name)
        return response.reply('(failed) ' + t('label.no_resources', name: name)) unless m.count > 0
        return response.reply('(successful) ' + t('label.lock', name: name)) if lock_label!(name, response.user, nil)

        response.reply(show_ownership(name))
      end

      def unlock(response)
        name = response.matches[0][0]
        return response.reply('(failed) ' + t('subject.does_not_exist', name: name)) unless label_exists?(name)
        l = label(name)
        return response.reply('(successful) ' + t('label.is_unlocked', name: name)) if l['state'] == 'unlocked'

        response.reply(attempt_unlock(name, l, response.user))
      end

      def steal(response)
        name = response.matches[0][0]
        return response.reply('(failed) ' + t('subject.does_not_exist', name: name)) unless label_exists?(name)
        l = label(name)
        return response.reply(t('steal.already_unlocked', label: name)) unless l['state'] == 'locked'

        response.reply(attempt_steal(name, l, response.user))
      end

      private

      def show_ownership(name)
        l = label(name)
        return show_dependencies(name) unless l['state'] == 'locked'
        o = Lita::User.find_by_id(l['owner_id'])
        if o.mention_name
          return '(failed) ' + t('label.owned_mention', name: name, owner_name: o.name, owner_mention: o.mention_name)
        else
          return '(failed) ' + t('label.owned', name: name, owner_name: o.name)
        end
      end

      def show_dependencies(name)
        msg = '(failed) ' + t('label.dependency') + "\n"
        deps = []
        label_membership(name).each do |resource_name|
          resource = resource(resource_name)
          u = Lita::User.find_by_id(resource['owner_id'])
          if resource['state'] == 'locked'
            deps.push "#{resource_name} - #{u.name}"
          end
        end
        msg += deps.join("\n")
        msg
      end

      def attempt_steal(name, label, user)
        o = Lita::User.find_by_id(label['owner_id'])
        return t('steal.self') if o.id == user.id
        unlock_label!(name)
        lock_label!(name, user, nil)
        mention = o.mention_name ? "(@#{o.mention_name})" : ''
        '(successful) ' + t('steal.stolen', label: name, old_owner: o.name, mention: mention)
      end

      def attempt_unlock(name, label, user)
        if user.id == label['owner_id']
          unlock_label!(name)
          return '(successful) ' + t('label.unlock', name: name)
        else
          o = Lita::User.find_by_id(label['owner_id'])
          if o.mention_name
            return '(failed) ' + t('label.owned_mention', name: name, owner_name: o.name, owner_mention: o.mention_name)
          else
            return '(failed) ' + t('label.owned', name: name, owner_name: o.name)
          end
        end
      end
    end

    Lita.register_handler(Locker)
  end
end
