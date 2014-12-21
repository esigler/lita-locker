# Locker subsystem
module Locker
  # Regex definitions
  module Regex
    LABEL_REGEX    = /([\.\w\s-]+)/
    RESOURCE_REGEX = /([\.\w-]+)/
    COMMENT_REGEX  = /(\s\#.+)?/
    LOCK_REGEX     = /\(lock\)\s/i
    USER_REGEX     = /(?:@)?(?<username>[\w\s]+)/
    UNLOCK_REGEX   = /(?:\(unlock\)|\(release\))\s/i
  end
end
