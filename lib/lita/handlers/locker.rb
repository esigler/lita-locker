module Lita
  module Handlers
    class Locker < Handler
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
    end

    Lita.register_handler(Locker)
  end
end
