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
        /^locker\sresource\screate\s#{RESOURCES_REGEX}$/,
        :create,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.create.syntax') => t('help.resource.create.desc')
        }
      )

      route(
        /^locker\sresource\sdelete\s#{RESOURCES_REGEX}$/,
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
        Resource.list.each_slice(10) do |slice|
          slice.each do |r|
            res = Resource.new(r)
            response.reply(t('resource.desc', name: r, state: res.state.value))
          end
          sleep 1
        end
      end

      def create(response)
        names = response.match_data['resources'].split(/,\s*/)
        results = []

        names.each do |name|
          if Resource.exists?(name)
            results <<= t('resource.exists', name: name)
          else
            Resource.create(name)
            results <<= t('resource.created', name: name)
          end
        end

        response.reply(results.join(', '))
      end

      def delete(response)
        names = response.match_data['resources'].split(/,\s*/)
        results = []

        names.each do |name|
          if Resource.exists?(name)
            Resource.delete(name)
            results <<= t('resource.deleted', name: name)
          else
            results <<= t('resource.does_not_exist', name: name)
          end
        end

        response.reply(results.join(', '))
      end

      def show(response)
        name = response.match_data['resource']
        return response.reply(t('resource.does_not_exist', name: name)) unless Resource.exists?(name)
        r = Resource.new(name)
        resp = t('resource.desc', name: name, state: r.state.value)
        if r.labels.count > 0
          resp += ', used by: '
          r.labels.each do |label|
            resp += Label.new(label).id
          end
        end
        response.reply(resp)
      end

      Lita.register_handler(LockerResources)
    end
  end
end
