# Locker subsystem
module Locker
  # Regex definitions
  module Regex
    LABEL_REGEX    = /(?<label>[\.\w\s-]+)(\s)?/
    RESOURCE_REGEX = /(?<resource>[\.\w-]+)/
    COMMENT_REGEX  = /(\s\#.+)?/
    LOCK_REGEX     = /\(lock\)\s/i
    USER_REGEX     = /(?:@)?(?<username>[\w\s]+)/
    UNLOCK_REGEX   = /(?:\(unlock\)|\(release\))\s/i
  end
end
