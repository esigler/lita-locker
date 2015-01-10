module Lita
  module Handlers
    # HTTP-related handlers
    class LockerHttp < Handler
      namespace 'Locker'

      include ::Locker::Label
      include ::Locker::Misc
      include ::Locker::Regex
      include ::Locker::Resource

      http.get '/locker/label/:name', :label_show
      http.get '/locker/resource/:name', :resource_show

      def label_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        unless Label.exists?(name)
          response.status = 404
          return
        end
        l = Label.new(name)
        response.write(l.to_json)
      end

      def resource_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        unless Resource.exists?(name)
          response.status = 404
          return
        end
        r = Resource.new(name)
        response.write(r.to_json)
      end

      Lita.register_handler(LockerHttp)
    end
  end
end
