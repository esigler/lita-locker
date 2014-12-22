require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'locker/label'
require 'locker/misc'
require 'locker/regex'
require 'locker/resource'

require 'lita/handlers/locker_events'
require 'lita/handlers/locker_http'
require 'lita/handlers/locker_labels'
require 'lita/handlers/locker_misc'
require 'lita/handlers/locker_resources'
require 'lita/handlers/locker'
