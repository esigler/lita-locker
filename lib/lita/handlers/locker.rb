module Lita
  module Handlers
    class Locker < Handler
      http.get '/locker/label/:name', :http_label_show
      http.get '/locker/resource/:name', :http_resource_show

      route(
        /^\(lock\)\s([a-zA-Z0-9]+)$/,
        :lock
      )

      route(
        /^\(unlock\)\s([a-zA-Z0-9]+)$/,
        :unlock
      )

      route(
        /^lock\s([a-zA-Z0-9]+)$/,
        :lock,
        command: true,
        help: {
          t('help.lock_key') => t('help.lock_value')
        }
      )

      route(
        /^unlock\s([a-zA-Z0-9]+)$/,
        :unlock,
        command: true,
        help: {
          t('help.unlock_key') => t('help.unlock_value')
        }
      )

      route(
        /^unlock\s([a-zA-Z0-9]+)\sforce$/,
        :unlock_force,
        command: true,
        help: {
          t('help.unlock_force_key') => t('help.unlock_force_value')
        }
      )

      route(
        /^locker\sresource\slist$/,
        :resource_list,
        command: true,
        help: {
          t('help.resource_list_key') =>
          t('help.resource_list_value')
        }
      )

      route(
        /^locker\sresource\screate\s([a-zA-Z0-9]+)$/,
        :resource_create,
        command: true,
        help: {
          t('help.resource_create_key') =>
          t('help.resource_create_value')
        }
      )

      route(
        /^locker\sresource\sdelete\s([a-zA-Z0-9]+)$/,
        :resource_delete,
        command: true,
        help: {
          t('help.resource_delete_key') =>
          t('help.resource_delete_value')
        }
      )

      route(
        /^locker\slabel\slist$/,
        :label_list,
        command: true,
        help: {
          t('help.label_list_key') =>
          t('help.label_list_value')
        }
      )

      route(
        /^locker\slabel\screate\s([a-zA-Z0-9]+)$/,
        :label_create,
        command: true,
        help: {
          t('help.label_create_key') =>
          t('help.label_create_value')
        }
      )

      route(
        /^locker\slabel\sdelete\s([a-zA-Z0-9]+)$/,
        :label_delete,
        command: true,
        help: {
          t('help.label_delete_key') =>
          t('help.label_delete_value')
        }
      )

      route(
        /^locker\slabel\sshow\s([a-zA-Z0-9]+)$/,
        :label_show,
        command: true,
        help: {
          t('help.label_show_key') =>
          t('help.label_show_value')
        }
      )

      route(
        /^locker\slabel\sadd\s([a-zA-Z0-9]+)\sto\s([a-zA-Z0-9]+)$/,
        :label_add,
        command: true,
        help: {
          t('help.label_add_key') =>
          t('help.label_add_value')
        }
      )

      route(
        /^locker\slabel\sremove\s([a-zA-Z0-9]+)\sfrom\s([a-zA-Z0-9]+)$/,
        :label_remove,
        command: true,
        help: {
          t('help.label_remove_key') =>
          t('help.label_remove_value')
        }
      )

      def http_label_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        result = label(name)
        response.write(result.to_json)
      end

      def http_resource_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        result = resource(name)
        response.write(result.to_json)
      end

      def lock(response)
        name = response.matches[0][0]
        if resource_exists?(name)
          if lock_resource!(name, response.user)
            response.reply(t('resource.lock', name: name))
          else
            response.reply(t('resource.is_locked', name: name))
          end
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def unlock(response)
        name = response.matches[0][0]
        if resource_exists?(name)
          res = resource(name)
          if res['state'] == 'unlocked'
            response.reply(t('resource.is_unlocked', name: name))
          else
            # FIXME: NOT SECURE
            if response.user.name == res['owner']
              unlock_resource!(name)
              response.reply(t('resource.unlock', name: name))
              # FIXME: Handle the case where things can't be unlocked?
            else
              response.reply(t('resource.owned', name: name,
                                                 owner: res['owner']))
            end
          end
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def unlock_force(response)
        name = response.matches[0][0]
        if resource_exists?(name)
          unlock_resource!(name)
          response.reply(t('resource.unlock', name: name))
          # FIXME: Handle the case where things can't be unlocked?
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def label_list(response)
        labels.each do |l|
          response.reply(t('label.desc', name: l.sub('label_', '')))
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
        resources.each do |r|
          response.reply(t('resource.desc', name: r.sub('resource_', '')))
        end
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

      private

      def create_label(name)
        label_key = "label_#{name}"
        redis.hset(label_key, 'state', 'unlocked') unless
          label_exists?(name)
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
          resource_exists?(name)
      end

      def delete_resource(name)
        resource_key = "resource_#{name}"
        redis.del(resource_key) if resource_exists?(name)
      end

      def resource_exists?(name)
        redis.exists("resource_#{name}")
      end

      def lock_resource!(name, owner)
        if resource_exists?(name)
          resource_key = "resource_#{name}"
          value = redis.hget(resource_key, 'state')
          if value == 'unlocked'
            # FIXME: Race condition!
            # FIXME: Need to track who did what
            # FIXME: Security!
            redis.hset(resource_key, 'state', 'locked')
            redis.hset(resource_key, 'owner', owner.name)
            true
          else
            false
          end
        else
          false
        end
      end

      def unlock_resource!(name)
        if resource_exists?(name)
          # FIXME: Tracking here?
          redis.hset("resource_#{name}", 'state', 'unlocked')
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
