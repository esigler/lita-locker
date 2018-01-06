# frozen_string_literal: true

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
        /^locker\slabel\slist#{COMMENT_REGEX}/,
        :list,
        command: true,
        kwargs: { page: { default: 1 } },
        help: { t('help.label.list.syntax') => t('help.label.list.desc') }
      )

      route(
        /^locker\slabel\screate\s#{LABELS_REGEX}#{COMMENT_REGEX}$/,
        :create,
        command: true,
        help: { t('help.label.create.syntax') => t('help.label.create.desc') }
      )

      route(
        /^locker\slabel\sdelete\s#{LABELS_REGEX}#{COMMENT_REGEX}$/,
        :delete,
        command: true,
        help: { t('help.label.delete.syntax') => t('help.label.delete.desc') }
      )

      route(
        /^locker\slabel\sshow\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :show,
        command: true,
        help: { t('help.label.show.syntax') => t('help.label.show.desc') }
      )

      route(
        /^locker\slabel\sadd\s#{RESOURCES_REGEX}\sto\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :add,
        command: true,
        help: { t('help.label.add.syntax') => t('help.label.add.desc') }
      )

      route(
        /^locker\slabel\sremove\s#{RESOURCES_REGEX}\sfrom\s#{LABEL_REGEX}#{COMMENT_REGEX}$/,
        :remove,
        command: true,
        help: { t('help.label.remove.syntax') => t('help.label.remove.desc') }
      )

      def list(response)
        list = Label.list
        count = list.count

        begin
          page = Integer(response.extensions[:kwargs][:page].to_s, 10)
        rescue ArgumentError
          response.reply t("list.invalid_page_type")

          return
        end

        pages = (count / config.per_page).ceil + 1

        if page < 1 || page > pages
          response.reply t("list.page_outside_range", pages: pages)

          return
        end

        offset = config.per_page * (page - 1)

        message = list[offset, config.per_page].map do |key|
          label = Label.new(key)

          state = label.state.value.to_s

          case state
          when 'unlocked'
            unlocked(t('label.desc', name: key, state: state))
          when 'locked'
            locked(t('label.desc', name: key, state: state))
          else
            # This case shouldn't happen, but it will if someone a label
            # gets saved with some other value for `state`.
            t('label.desc', name: key, state: state)
          end
        end.join("\n")

        if count > config.per_page
          message += "\n#{t('list.paginate', page: page, pages: pages)}"
        end

        response.reply(message)
      end

      def create(response)
        names = response.match_data['labels'].split(/,\s*/)
        results = []

        names.each do |name|
          results <<= if !Label.exists?(name) && Label.create(name)
                        t('label.created', name: name)
                      else
                        t('label.exists', name: name)
                      end
        end

        response.reply(results.join(', '))
      end

      def delete(response)
        names = response.match_data['labels'].split(/,\s*/)
        results = []

        names.each do |name|
          results <<= if Label.exists?(name) && Label.delete(name)
                        t('label.deleted', name: name)
                      else
                        failed(t('label.does_not_exist', name: name))
                      end
        end

        response.reply(results.join(', '))
      end

      def show(response)
        name = response.match_data['label']
        return response.reply(failed(t('label.does_not_exist', name: name))) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.has_no_resources', name: name)) unless l.membership.count.positive?
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
