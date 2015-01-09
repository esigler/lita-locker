module Lita
  module Handlers
    # Resource-related handlers
    class LockerResources < Handler
      namespace 'Locker'

      include ::Locker::Label
      include ::Locker::Misc
      include ::Locker::Regex
      include ::Locker::Resource

      route(
        /^locker\sresource\slist$/,
        :list,
        command: true,
        help: { t('help.resource.list.syntax') => t('help.resource.list.desc') }
      )

      route(
        /^locker\sresource\screate\s#{RESOURCE_REGEX}$/,
        :create,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.create.syntax') => t('help.resource.create.desc')
        }
      )

      route(
        /^locker\sresource\sdelete\s#{RESOURCE_REGEX}$/,
        :delete,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.delete.syntax') => t('help.resource.delete.desc')
        }
      )

      route(
        /^locker\sresource\sshow\s#{RESOURCE_REGEX}$/,
        :show,
        command: true,
        help: { t('help.resource.show.syntax') => t('help.resource.show.desc') }
      )

      def list(response)
        output = ''
        Resource.list.each do |r|
          res = Resource.new(r)
          output += t('resource.desc', name: r, state: res.state.value)
        end
        response.reply(output)
      end

      def create(response)
        name = response.matches[0][0]
        return response.reply(t('resource.exists', name: name)) if Resource.exists?(name)
        Resource.create(name)
        response.reply(t('resource.created', name: name))
      end

      def delete(response)
        name = response.matches[0][0]
        return response.reply(t('resource.does_not_exist', name: name)) unless Resource.exists?(name)
        Resource.delete(name)
        response.reply(t('resource.deleted', name: name))
      end

      def show(response)
        name = response.matches[0][0]
        return response.reply(t('resource.does_not_exist', name: name)) unless Resource.exists?(name)
        r = Resource.new(name)
        response.reply(t('resource.desc', name: name, state: r.state.value))
      end

      Lita.register_handler(LockerResources)
    end
  end
end
