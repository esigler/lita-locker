module Lita
  module Handlers
    # HTTP-related handlers
    class LockerHttp < Handler
      namespace 'Locker'

      include ::Locker::Regex
      include ::Locker::Label
      include ::Locker::Resource

      http.get '/locker/label/:name', :http_label_show
      http.get '/locker/resource/:name', :http_resource_show

      def http_label_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        response.write(label(name).to_json)
      end

      def http_resource_show(request, response)
        name = request.env['router.params'][:name]
        response.headers['Content-Type'] = 'application/json'
        response.write(resource(name).to_json)
      end

      Lita.register_handler(LockerHttp)
    end
  end
end
