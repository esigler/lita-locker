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
        /^locker\sstatus\s#{LABEL_WILDCARD_REGEX}$/,
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

      route(
        /^locker\s(dq|dequeue)\s#{LABEL_REGEX}$/,
        :dequeue,
        command: true,
        help: { t('help.dequeue.syntax') => t('help.dequeue.desc') }
      )

      route(
        /^locker\slog\s#{LABEL_REGEX}$/,
        :log,
        command: true,
        help: { t('help.log.syntax.') => t('help.log.desc') }
      )

      def log(response)
        name = response.match_data['label']
        return response.reply(failed(t('subject.does_not_exist', name: name))) unless Label.exists?(name)
        l = Label.new(name)
        l.journal.range(-10, -1).each do |entry|
          response.reply(t('label.log_entry', entry: entry))
        end
      end

      def status(response)
        name = response.match_data['label']
        unless name =~ /\*/
          # Literal query
          return response.reply(status_label(name)) if Label.exists?(name)
          return response.reply(status_resource(name)) if Resource.exists?(name)
          return response.reply(failed(t('status.does_not_exist', name: name)))
        end
        # Wildcard query
        matcher = Regexp.new(name.gsub(/\*/, '.*'))
        labels = Label.list.select { |label| label =~ matcher }
        return response.reply(failed(t('status.does_not_exist', name: name))) if labels.empty?
        labels.each do |n|
          response.reply(status_label(n))
        end
      end

      def dequeue(response)
        name = response.match_data['label']
        user = response.user
        return response.reply(t('subject.does_not_exist', name: name)) unless Label.exists?(name)
        l = Label.new(name)
        return response.reply(t('label.unknown_in_queue', name: name, user: user.name)) unless l.wait_queue.include?(user.id)
        l.wait_queue.delete(user.id)
        l.dedupe!
        response.reply(t('label.removed_from_queue', name: name, user: user.name))
      end

      def list(response)
        username = response.match_data['username']
        user = Lita::User.fuzzy_find(username)
        return response.reply(t('user.unknown', user: username)) unless user
        l = user_locks(user)
        return response.reply(t('user.no_active_locks', user: user.name)) if l.empty?
        composed = ''
        l.each do |label_name|
          composed += "Label: #{label_name}\n"
        end
        response.reply(composed)
      end

      private

      def status_label(name)
        l = Label.new(name)
        return unlocked(t('label.desc', name: name, state: l.state.value)) unless l.locked?
        if l.wait_queue.count > 0
          queue = []
          l.wait_queue.each do |u|
            usr = Lita::User.find_by_id(u)
            queue.push(usr.name)
          end
          locked(t('label.desc_owner_queue', name: name,
                                             state: l.state.value,
                                             owner_name: l.owner.name,
                                             time: l.held_for,
                                             queue: queue.join(', ')))
        else
          locked(t('label.desc_owner', name: name,
                                       state: l.state.value,
                                       owner_name: l.owner.name,
                                       time: l.held_for))
        end
      end

      def status_resource(name)
        r = Resource.new(name)
        t('resource.desc', name: name, state: r.state.value)
      end

      Lita.register_handler(LockerMisc)
    end
  end
end
