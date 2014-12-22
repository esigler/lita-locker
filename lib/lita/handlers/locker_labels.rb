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
        return response.reply(t('label.does_not_exist', name: name)) unless label_exists?(name)
        members = label_membership(name)
        return response.reply(t('label.has_no_resources', name: name)) unless members.count > 0
        response.reply(t('label.resources', name: name,
                                            resources: members.join(', ')))
      end

      def label_add(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        return response.reply(t('label.does_not_exist', name: label_name)) unless label_exists?(label_name)
        return response.reply(t('resource.does_not_exist', name: resource_name)) unless resource_exists?(resource_name)
        add_resource_to_label(label_name, resource_name)
        response.reply(t('label.resource_added', label: label_name,
                                                 resource: resource_name))
      end

      def label_remove(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        return response.reply(t('label.does_not_exist', name: label_name)) unless label_exists?(label_name)
        return response.reply(t('resource.does_not_exist', name: resource_name)) unless resource_exists?(resource_name)
        members = label_membership(label_name)
        if members.include?(resource_name)
          remove_resource_from_label(label_name, resource_name)
          response.reply(t('label.resource_removed',
                           label: label_name, resource: resource_name))
        else
          response.reply(t('label.does_not_have_resource',
                           label: label_name, resource: resource_name))
        end
      end

      Lita.register_handler(LockerLabels)
    end
  end
end
