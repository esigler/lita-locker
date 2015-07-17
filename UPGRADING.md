# lita-locker upgrading

## Overview

lita-locker 1.x has a breaking data model change.  This enables a huge number
of new features, such as queueing and timestamps.  You'll need to export out
your existing data and bring it back in when you upgrade lita-locker.

As a note, the 0.x and 1.x plugins use different redis keysets, so it's possible
to upgrade to 1.x and retain your old data, should you need to downgrade for
some reason.  However, 1.x locks will not show up in 0.x clients, and vice-versa.

## Example migration script

The below is a no-warranties-provided Ruby script you can use to export your
existing data, and optionally remove the older information.

``
require 'redis'

bot_prefix = "!"
remove_old_data = false
redis = Redis.new
resources = []
labels = []

redis.keys('lita:handlers:locker:resource_*').each do |k|
  resources.push(k.gsub(/^lita:handlers:locker:resource_/, ''))
end

resources.each_slice(10) do |batch|
  puts "#{bot_prefix}locker resource create #{batch.join(', ')}\n\n"
end

redis.keys('lita:handlers:locker:label_*').each do |k|
  labels.push(k.gsub(/^lita:handlers:locker:label_/, ''))
end

labels.each_slice(10) do |batch|
  puts "#{bot_prefix}locker label create #{batch.join(', ')}\n\n"
end

labels.each do |label|
  members = []
  redis.smembers("lita:handlers:locker:membership_#{label}").each do |k|
    members.push(k)
  end
  puts "#{bot_prefix}locker label add #{members.join(', ')} to #{label}\n" if members.count > 0
end

if remove_old_data
  resources.each do |r|
    redis.del("lita:handlers:locker:resource_#{r}")
  end

  labels.each do |l|
    redis.del("lita:handlers:locker:label_#{l}")
    redis.del("lita:handlers:locker:membership_#{l}")
  end
end
``
