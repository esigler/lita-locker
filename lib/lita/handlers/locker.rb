module Lita
  # Handy, isn't it?
  module Handlers
    # Top-level class for Locker
    class Locker < Handler
      include ::Locker::Regex
      include ::Locker::Label
      include ::Locker::Resource

      on :lock_attempt, :lock_attempt
      on :unlock_attempt, :unlock_attempt

      http.get '/locker/label/:name', :http_label_show
      http.get '/locker/resource/:name', :http_resource_show

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

      route(
        /^locker\sstatus\s#{LABEL_REGEX}$/,
        :status,
        command: true,
        help: { t('help.status.syntax') => t('help.status.desc') }
      )

      route(
        /^locker\sresource\slist$/,
        :resource_list,
        command: true,
        help: { t('help.resource.list.syntax') => t('help.resource.list.desc') }
      )

      route(
        /^locker\sresource\screate\s#{RESOURCE_REGEX}$/,
        :resource_create,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.create.syntax') => t('help.resource.create.desc')
        }
      )

      route(
        /^locker\sresource\sdelete\s#{RESOURCE_REGEX}$/,
        :resource_delete,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.delete.syntax') => t('help.resource.delete.desc')
        }
      )

      route(
        /^locker\sresource\sshow\s#{RESOURCE_REGEX}$/,
        :resource_show,
        command: true,
        help: { t('help.resource.show.syntax') => t('help.resource.show.desc') }
      )

      route(
        /^locker\slist\s#{USER_REGEX}$/,
        :user_list,
        command: true,
        help: { t('help.list.syntax') => t('help.list.desc') }
      )

      def http_label_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        response.write(label(name).to_json)
      end

      def http_resource_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        response.write(resource(name).to_json)
      end

      def lock_attempt(payload)
        label      = payload[:label]
        user       = Lita::User.find_by_id(payload[:user_id])
        request_id = payload[:request_id]

        if label_exists?(label) && lock_label!(label, user, nil)
          robot.trigger(:lock_success, request_id: request_id)
        else
          robot.trigger(:lock_failure, request_id: request_id)
        end
      end

      def unlock_attempt(payload)
        label      = payload[:label]
        request_id = payload[:request_id]

        if label_exists?(label) && unlock_label!(label)
          robot.trigger(:unlock_success, request_id: request_id)
        else
          robot.trigger(:unlock_failure, request_id: request_id)
        end
      end

      def lock(response)
        name = response.matches[0][0]

        if label_exists?(name)
          m = label_membership(name)
          if m.count > 0
            if lock_label!(name, response.user, nil)
              response.reply('(successful) ' + t('label.lock', name: name))
            else
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
          else
            response.reply('(failed) ' + t('label.no_resources', name: name))
          end
        else
          response.reply('(failed) ' + t('label.does_not_exist', name: name))
        end
      end

      def unlock(response)
        name = response.matches[0][0]
        if label_exists?(name)
          l = label(name)
          if l['state'] == 'unlocked'
            response.reply('(successful) ' + t('label.is_unlocked',
                                               name: name))
          else
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
        else
          response.reply('(failed) ' + t('subject.does_not_exist', name: name))
        end
      end

      def steal(response)
        name = response.matches[0][0]
        if label_exists?(name)
          l = label(name)
          if l['state'] == 'locked'
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
          else
            response.reply(t('steal.already_unlocked', label: name))
          end
        else
          response.reply('(failed) ' + t('subject.does_not_exist', name: name))
        end
      end

      def status(response)
        name = response.matches[0][0]
        if label_exists?(name)
          l = label(name)
          if l['owner_id'] && l['owner_id'] != ''
            o = Lita::User.find_by_id(l['owner_id'])
            response.reply(t('label.desc_owner', name: name,
                                                 state: l['state'],
                                                 owner_name: o.name))
          else
            response.reply(t('label.desc', name: name, state: l['state']))
          end
        elsif resource_exists?(name)
          r = resource(name)
          response.reply(t('resource.desc', name: name, state: r['state']))
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def resource_list(response)
        output = ''
        resources.each do |r|
          r_name = r.sub('resource_', '')
          res = resource(r_name)
          output += t('resource.desc', name: r_name, state: res['state'])
        end
        response.reply(output)
      end

      def resource_create(response)
        name = response.matches[0][0]
        if create_resource(name)
          response.reply(t('resource.created', name: name))
        else
          response.reply(t('resource.exists', name: name))
        end
      end

      def resource_delete(response)
        name = response.matches[0][0]
        return response.reply(t('resource.does_not_exist', name: name)) unless resource_exists?(name)
        delete_resource(name)
        response.reply(t('resource.deleted', name: name))
      end

      def resource_show(response)
        name = response.matches[0][0]
        return response.reply(t('resource.does_not_exist', name: name)) unless resource_exists?(name)
        r = resource(name)
        response.reply(t('resource.desc', name: name, state: r['state']))
      end

      def user_list(response)
        username = response.match_data['username']
        user = Lita::User.fuzzy_find(username)
        return response.reply('Unknown user') unless user
        l = user_locks(user)
        return response.reply('That user has no active locks') unless l.size > 0
        composed = ''
        l.each do |label_name|
          composed += "Label: #{label_name}\n"
        end
        response.reply(composed)
      end

      private

      def user_locks(user)
        owned = []
        labels.each do |name|
          name.slice! 'label_'
          label = label(name)
          owned.push(name) if label['owner_id'] == user.id
        end
        owned
      end
    end

    Lita.register_handler(Locker)
  end
end
