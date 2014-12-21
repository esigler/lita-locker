module Lita
  module Handlers
    # Label-related handlers
    class LockerResources < Handler
      namespace 'Locker'

      include ::Locker::Regex
      include ::Locker::Label
      include ::Locker::Resource

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

      Lita.register_handler(LockerResources)
    end
  end
end
