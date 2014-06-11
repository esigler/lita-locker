module Lita
  module Handlers
    class Locker < Handler
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
          state = show_resource(name)
          if state == 'unlocked'
            response.reply(t('resource.is_unlocked', name: name))
          else
            if response.user.name == state
              if unlock_resource!(name)
                response.reply(t('resource.unlock', name: name))
              end
              # FIXME: Handle the case where things can't be unlocked?
            else
              response.reply(t('resource.owned', name: name, owner: state))
            end
          end
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def unlock_force(response)
        name = response.matches[0][0]
        if resource_exists?(name)
          if unlock_resource!(name)
            response.reply(t('resource.unlock', name: name))
          end
        else
          response.reply(t('subject.does_not_exist', name: name))
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
        redis.set(resource_key, 'unlocked') unless resource_exists?(name)
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
          value = redis.get(resource_key)
          if value == 'unlocked'
            # FIXME: Race condition!
            # FIXME: Need to track who did what
            # FIXME: Security!
            redis.set(resource_key, owner.name)
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
          redis.set("resource_#{name}", 'unlocked')
        else
          false
        end
      end

      def show_resource(name)
        return redis.get("resource_#{name}") if resource_exists?(name)
      end
    end

    Lita.register_handler(Locker)
  end
end
