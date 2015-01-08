module Lita
  module Handlers
    # Misc Locker handlers
    class LockerMisc < Handler
      namespace 'Locker'

      include ::Locker::Label
      include ::Locker::Misc
      include ::Locker::Regex
      include ::Locker::Resource

      route(
        /^locker\sstatus\s#{LABEL_REGEX}$/,
        :status,
        command: true,
        help: { t('help.status.syntax') => t('help.status.desc') }
      )

      route(
        /^locker\slist\s#{USER_REGEX}$/,
        :list,
        command: true,
        help: { t('help.list.syntax') => t('help.list.desc') }
      )

      def status(response)
        name = response.matches[0][0]
        if Label.exists?(name)
          l = label(name)
          if l.owner_id.value != ''
            o = Lita::User.find_by_id(l.owner_id.value)
            response.reply(t('label.desc_owner', name: name, state: l.state.value, owner_name: o.name))
          else
            response.reply(t('label.desc', name: name, state: l.state.value))
          end
        elsif resource_exists?(name)
          r = resource(name)
          response.reply(t('resource.desc', name: name, state: r.state.value))
        else
          response.reply(t('subject.does_not_exist', name: name))
        end
      end

      def list(response)
        username = response.match_data['username']
        user = Lita::User.fuzzy_find(username)
        return response.reply(t('user.unknown')) unless user
        l = user_locks(user)
        return response.reply(t('user.no_active_locks')) unless l.size > 0
        composed = ''
        l.each do |label_name|
          composed += "Label: #{label_name}\n"
        end
        response.reply(composed)
      end

      Lita.register_handler(LockerMisc)
    end
  end
end
