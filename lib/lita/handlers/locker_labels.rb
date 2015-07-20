module Lita
  module Handlers
    # Label-related handlers
    class LockerLabels < Handler
      namespace 'Locker'

      include ::Locker::Label
      include ::Locker::Misc
      include ::Locker::Regex
      include ::Locker::Resource

      route(
        /^locker\slabel\slist$/,
        :list,
        command: true,
        help: { t('help.label.list.syntax') => t('help.label.list.desc') }
      )

      route(
        /^locker\slabel\screate\s#{LABELS_REGEX}$/,
        :create,
        command: true,
        help: { t('help.label.create.syntax') => t('help.label.create.desc') }
      )

      route(
        /^locker\slabel\sdelete\s#{LABELS_REGEX}$/,
        :delete,
        command: true,
        help: { t('help.label.delete.syntax') => t('help.label.delete.desc') }
      )

      route(
        /^locker\slabel\sshow\s#{LABEL_REGEX}$/,
        :show,
        command: true,
        help: { t('help.label.show.syntax') => t('help.label.show.desc') }
      )

      route(
        /^locker\slabel\sadd\s#{RESOURCES_REGEX}\sto\s#{LABEL_REGEX}$/,
        :add,
        command: true,
        help: { t('help.label.add.syntax') => t('help.label.add.desc') }
      )

      route(
        /^locker\slabel\sremove\s#{RESOURCES_REGEX}\sfrom\s#{LABEL_REGEX}$/,
        :remove,
        command: true,
        help: { t('help.label.remove.syntax') => t('help.label.remove.desc') }
      )

      def list(response)
        after 0 do
          should_rate_limit = false

          Label.list.each_slice(5) do |slice|
            if should_rate_limit
              sleep 3
            else
              should_rate_limit = true
            end

            slice.each do |n|
              l = Label.new(n)
              response.reply(unlocked(t('label.desc', name: n, state: l.state.value)))
            end
          end
        end
      end

      def create(response)
        names = response.match_data['labels'].split(/,\s*/)
        results = []

        names.each do |name|
          if !Label.exists?(name) && Label.create(name)
            results <<= t('label.created', name: name)
          else
            results <<= t('label.exists', name: name)
          end
        end

        response.reply(results.join(', '))
      end

      def delete(response)
        names = response.match_data['labels'].split(/,\s*/)
        results = []

        names.each do |name|
          if Label.exists?(name) && Label.delete(name)
            results <<= t('label.deleted', name: name)
          else
            results <<= failed(t('label.does_not_exist', name: name))
          end
        end

        response.reply(results.join(', '))
      end

      def show(response)
        name = response.match_data['label']
        return response.reply(failed(t('label.does_not_exist', name: name))) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.has_no_resources', name: name)) unless l.membership.count > 0
        res = []
        l.membership.each do |member|
          res.push(member)
        end
        response.reply(t('label.resources', name: name, resources: res.join(', ')))
      end

      def add(response)
        results = []
        resource_names = response.match_data['resources'].split(/,\s*/)
        label_name = response.match_data['label']
        return response.reply(failed(t('label.does_not_exist', name: label_name))) unless Label.exists?(label_name)

        resource_names.each do |resource_name|
          if Resource.exists?(resource_name)
            l = Label.new(label_name)
            r = Resource.new(resource_name)
            l.add_resource(r)
            results <<= t('label.resource_added', label: label_name, resource: resource_name)
          else
            results <<= t('resource.does_not_exist', name: resource_name)
          end
        end

        response.reply(results.join(', '))
      end

      def remove(response)
        results = []
        resource_names = response.match_data['resources'].split(/,\s*/)
        label_name = response.match_data['label']
        return response.reply(failed(t('label.does_not_exist', name: label_name))) unless Label.exists?(label_name)

        resource_names.each do |resource_name|
          if Resource.exists?(resource_name)
            l = Label.new(label_name)
            if l.membership.include?(resource_name)
              r = Resource.new(resource_name)
              l.remove_resource(r)
              results <<= t('label.resource_removed', label: label_name, resource: resource_name)
            else
              results <<= t('label.does_not_have_resource', label: label_name, resource: resource_name)
            end
          else
            results <<= t('resource.does_not_exist', name: resource_name)
          end
        end

        response.reply(results.join(', '))
      end

      Lita.register_handler(LockerLabels)
    end
  end
end
