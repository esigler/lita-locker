require 'lita'

Lita.load_locales Dir[File.expand_path(
  File.join('..', '..', 'locales', '*.yml'), __FILE__
)]

require 'locker/label'
require 'locker/resource'

require 'lita/handlers/locker'
