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
        /^locker\slabel\screate\s#{LABEL_REGEX}$/,
        :create,
        command: true,
        help: { t('help.label.create.syntax') => t('help.label.create.desc') }
      )

      route(
        /^locker\slabel\sdelete\s#{LABEL_REGEX}$/,
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
        /^locker\slabel\sadd\s#{RESOURCE_REGEX}\sto\s#{LABEL_REGEX}$/,
        :add,
        command: true,
        help: { t('help.label.add.syntax') => t('help.label.add.desc') }
      )

      route(
        /^locker\slabel\sremove\s#{RESOURCE_REGEX}\sfrom\s#{LABEL_REGEX}$/,
        :remove,
        command: true,
        help: { t('help.label.remove.syntax') => t('help.label.remove.desc') }
      )

      def list(response)
        Label.list.each do |n|
          l = Label.new(n)
          response.reply(t('label.desc', name: n, state: l.state.value))
        end
      end

      def create(response)
        name = response.matches[0][0]
        if !Label.exists?(name) && Label.create(name)
          response.reply(t('label.created', name: name))
        else
          response.reply(t('label.exists', name: name))
        end
      end

      def delete(response)
        name = response.matches[0][0]
        if Label.exists?(name) && Label.delete(name)
          response.reply(t('label.deleted', name: name))
        else
          response.reply(t('label.does_not_exist', name: name))
        end
      end

      def show(response)
        name = response.matches[0][0]
        return response.reply(t('label.does_not_exist', name: name)) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.has_no_resources', name: name)) unless l.membership.count > 0
        res = []
        l.membership.each do |member|
          res.push(member)
        end
        response.reply(t('label.resources', name: name, resources: res.join(', ')))
      end

      def add(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        return response.reply(t('label.does_not_exist', name: label_name)) unless Label.exists?(label_name)
        return response.reply(t('resource.does_not_exist', name: resource_name)) unless Resource.exists?(resource_name)
        l = Label.new(label_name)
        r = Resource.new(resource_name)
        l.add_resource(r)
        response.reply(t('label.resource_added', label: label_name, resource: resource_name))
      end

      def remove(response)
        resource_name = response.matches[0][0]
        label_name = response.matches[0][1]
        return response.reply(t('label.does_not_exist', name: label_name)) unless Label.exists?(label_name)
        return response.reply(t('resource.does_not_exist', name: resource_name)) unless Resource.exists?(resource_name)
        l = Label.new(label_name)
        if l.membership.include?(resource_name)
          r = Resource.new(resource_name)
          l.remove_resource(r)
          response.reply(t('label.resource_removed', label: label_name, resource: resource_name))
        else
          response.reply(t('label.does_not_have_resource', label: label_name, resource: resource_name))
        end
      end

      Lita.register_handler(LockerLabels)
    end
  end
end
