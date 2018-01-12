# frozen_string_literal: true

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
        /^locker\sresource\slist/,
        :list,
        command: true,
        kwargs: { page: { default: 1 } },
        help: { t('help.resource.list.syntax') => t('help.resource.list.desc') }
      )

      route(
        /^locker\sresource\screate\s#{RESOURCES_REGEX}#{COMMENT_REGEX}$/,
        :create,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.create.syntax') => t('help.resource.create.desc')
        }
      )

      route(
        /^locker\sresource\sdelete\s#{RESOURCES_REGEX}#{COMMENT_REGEX}$/,
        :delete,
        command: true,
        restrict_to: [:locker_admins],
        help: {
          t('help.resource.delete.syntax') => t('help.resource.delete.desc')
        }
      )

      route(
        /^locker\sresource\sshow\s#{RESOURCE_REGEX}#{COMMENT_REGEX}$/,
        :show,
        command: true,
        help: { t('help.resource.show.syntax') => t('help.resource.show.desc') }
      )

      def list(response)
        list = Resource.list
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
          resource = Resource.new(key)

          state = resource.state.value

          case state
          when 'unlocked'
            unlocked(t('resource.desc', name: key, state: state))
          when 'locked'
            locked(t('resource.desc', name: key, state: state))
          else
            # This case shouldn't happen, but it will if a label
            # gets saved with some other value for `state`.
            t('resource.desc', name: key, state: state)
          end
        end.join("\n")

        if count > config.per_page
          message += "\n#{t('list.paginate', page: page, pages: pages)}"
        end

        response.reply(message)
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
        if r.labels.count.positive?
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
