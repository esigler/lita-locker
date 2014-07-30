module Lita
  module Handlers
    class Locker < Handler
      http.get '/locker/label/:name', :http_label_show
      http.get '/locker/resource/:name', :http_resource_show

      LABEL_REGEX    = /([\.\w\s-]+)/
      RESOURCE_REGEX = /([\.\w-]+)/
      COMMENT_REGEX  = /(\s\#.+)?/

      route(
        /^\(lock\)\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :lock
      )

      route(
        /^(?:\(unlock\)|\(release\))\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
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
        /^locker\slabel\slist$/,
        :label_list,
        command: true,
        help: { t('help.label.list.syntax') => t('help.label.list.desc') }
      )

      route(
        /^locker\slabel\screate\s#{LABEL_REGEX}$/,
        :label_create,
        command: true,
        help: { t('help.label.create.syntax') => t('help.label.create.desc') }
      )

      route(
        /^locker\slabel\sdelete\s#{LABEL_REGEX}$/,
        :label_delete,
        command: true,
        help: { t('help.label.delete.syntax') => t('help.label.delete.desc') }
      )

      route(
        /^locker\slabel\sshow\s#{LABEL_REGEX}$/,
        :label_show,
        command: true,
        help: { t('help.label.show.syntax') => t('help.label.show.desc') }
      )

      route(
        /^locker\slabel\sadd\s#{RESOURCE_REGEX}\sto\s#{LABEL_REGEX}$/,
        :label_add,
        command: true,
        help: { t('help.label.add.syntax') => t('help.label.add.desc') }
      )

      route(
        /^locker\slabel\sremove\s#{RESOURCE_REGEX}\sfrom\s#{LABEL_REGEX}$/,
        :label_remove,
        command: true,
        help: { t('help.label.remove.syntax') => t('help.label.remove.desc') }
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
                response.reply('(failed) ' + t('label.dependency'))
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
          unlock_label!(name)
          response.reply('(successful) ' + t('label.unlock', name: name))
          # FIXME: Handle the case where things can't be unlocked?
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

      def label_list(response)
        labels.sort.each do |n|
          name = n.sub('label_', '')
          l = label(name)
          response.reply(t('label.desc', name: name, state: l['state']))
        end
      end

      def label_create(response)
        name = response.matches[0][0]
        if create_label(name)
          response.reply(t('label.created', name: name))
        else
          response.reply(t('label.exists', name: name))
        end
      end

      def label_delete(response)
        name = response.matches[0][0]
        if delete_label(name)
          response.reply(t('label.deleted', name: name))
        else
          response.reply(t('label.does_not_exist', name: name))
        end
      end

      def label_show(response)
        name = response.matches[0][0]
        if label_exists?(name)
          members = label_membership(name)
          if members.count > 0
            response.reply(t('label.resources', name: name,
                                                resources: members.join(', ')))
          else
            response.reply(t('label.has_no_resources', name: name))
          end
        else
          response.reply(t('label.does_not_exist', name: name))
        end
      end

      def label_add(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        if label_exists?(label_name)
          if resource_exists?(resource_name)
            add_resource_to_label(label_name, resource_name)
            response.reply(t('label.resource_added', label: label_name,
                                                     resource: resource_name))
          else
            response.reply(t('resource.does_not_exist', name: resource_name))
          end
        else
          response.reply(t('label.does_not_exist', name: label_name))
        end
      end

      def label_remove(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        if label_exists?(label_name)
          if resource_exists?(resource_name)
            members = label_membership(label_name)
            if members.include?(resource_name)
              remove_resource_from_label(label_name, resource_name)
              response.reply(t('label.resource_removed',
                               label: label_name, resource: resource_name))
            else
              response.reply(t('label.does_not_have_resource',
                               label: label_name, resource: resource_name))
            end
          else
            response.reply(t('resource.does_not_exist', name: resource_name))
          end
        else
          response.reply(t('label.does_not_exist', name: label_name))
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
        if delete_resource(name)
          response.reply(t('resource.deleted', name: name))
        else
          response.reply(t('resource.does_not_exist', name: name))
        end
      end

      def resource_show(response)
        name = response.matches[0][0]
        if resource_exists?(name)
          r = resource(name)
          response.reply(t('resource.desc', name: name, state: r['state']))
        else
          response.reply(t('resource.does_not_exist', name: name))
        end
      end

      private

      def create_label(name)
        label_key = "label_#{name}"
        redis.hset(label_key, 'state', 'unlocked') unless
          resource_exists?(name) || label_exists?(name)
      end

      def delete_label(name)
        label_key = "label_#{name}"
        redis.del(label_key) if label_exists?(name)
      end

      def label_exists?(name)
        redis.exists("label_#{name}")
      end

      def label_membership(name)
        redis.smembers("membership_#{name}")
      end

      def add_resource_to_label(label, resource)
        if label_exists?(label) && resource_exists?(resource)
          redis.sadd("membership_#{label}", resource)
        end
      end

      def remove_resource_from_label(label, resource)
        if label_exists?(label) && resource_exists?(resource)
          redis.srem("membership_#{label}", resource)
        end
      end

      def create_resource(name)
        resource_key = "resource_#{name}"
        redis.hset(resource_key, 'state', 'unlocked') unless
          resource_exists?(name) || label_exists?(name)
      end

      def delete_resource(name)
        resource_key = "resource_#{name}"
        redis.del(resource_key) if resource_exists?(name)
      end

      def resource_exists?(name)
        redis.exists("resource_#{name}")
      end

      def lock_resource!(name, owner, time_until)
        if resource_exists?(name)
          resource_key = "resource_#{name}"
          value = redis.hget(resource_key, 'state')
          if value == 'unlocked'
            # FIXME: Race condition!
            redis.hset(resource_key, 'state', 'locked')
            redis.hset(resource_key, 'owner_id', owner.id)
            redis.hset(resource_key, 'until', time_until)
            true
          else
            false
          end
        else
          false
        end
      end

      def lock_label!(name, owner, time_until)
        if label_exists?(name)
          key = "label_#{name}"
          members = label_membership(name)
          members.each do |m|
            return false unless lock_resource!(m, owner, time_until)
          end
          redis.hset(key, 'state', 'locked')
          redis.hset(key, 'owner_id', owner.id)
          redis.hset(key, 'until', time_until)
          true
        else
          false
        end
      end

      def unlock_resource!(name)
        if resource_exists?(name)
          key = "resource_#{name}"
          redis.hset(key, 'state', 'unlocked')
          redis.hset(key, 'owner_id', '')
        else
          false
        end
      end

      def unlock_label!(name)
        if label_exists?(name)
          key = "label_#{name}"
          members = label_membership(name)
          members.each do |m|
            unlock_resource!(m)
          end
          redis.hset(key, 'state', 'unlocked')
          redis.hset(key, 'owner_id', '')
          true
        else
          false
        end
      end

      def resource(name)
        redis.hgetall("resource_#{name}")
      end

      def resources
        redis.keys('resource_*')
      end

      def label(name)
        redis.hgetall("label_#{name}")
      end

      def labels
        redis.keys('label_*')
      end
    end

    Lita.register_handler(Locker)
  end
end
