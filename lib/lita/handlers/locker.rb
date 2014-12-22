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

        l = label(name)
        if l['state'] == 'locked'
          o = Lita::User.find_by_id(l['owner_id'])
          if o.mention_name
            response.reply('(failed) ' + t('label.owned_mention',
                                           name: name,
                                           owner_name: o.name,
                                           owner_mention: o.mention_name))
          else
            response.reply('(failed) ' + t('label.owned',
                                           name: name,
                                           owner_name: o.name))
          end
        else
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
          response.reply(msg)
        end
      end

      def unlock(response)
        name = response.matches[0][0]
        return response.reply('(failed) ' + t('subject.does_not_exist', name: name)) unless label_exists?(name)
        l = label(name)
        return response.reply('(successful) ' + t('label.is_unlocked', name: name)) if l['state'] == 'unlocked'

        if response.user.id == l['owner_id']
          unlock_label!(name)
          response.reply('(successful) ' + t('label.unlock', name: name))
        else
          o = Lita::User.find_by_id(l['owner_id'])
          if o.mention_name
            response.reply('(failed) ' + t('label.owned_mention',
                                           name: name,
                                           owner_name: o.name,
                                           owner_mention: o.mention_name))
          else
            response.reply('(failed) ' + t('label.owned',
                                           name: name,
                                           owner_name: o.name))
          end
        end
      end

      def steal(response)
        name = response.matches[0][0]
        return response.reply('(failed) ' + t('subject.does_not_exist', name: name)) unless label_exists?(name)
        l = label(name)
        return response.reply(t('steal.already_unlocked', label: name)) unless l['state'] == 'locked'
        o = Lita::User.find_by_id(l['owner_id'])
        if o.id != response.user.id
          unlock_label!(name)
          lock_label!(name, response.user, nil)
          mention = o.mention_name ? "(@#{o.mention_name})" : ''
          response.reply('(successful) ' + t('steal.stolen',
                                             label: name,
                                             old_owner: o.name,
                                             mention: mention))
        else
          response.reply(t('steal.self'))
        end
      end
    end

    Lita.register_handler(Locker)
  end
end
