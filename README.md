# lita-locker

[![Build Status](https://img.shields.io/travis/esigler/lita-locker/master.svg)](https://travis-ci.org/esigler/lita-locker)
[![MIT License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](https://tldrlegal.com/license/mit-license)
[![RubyGems :: RMuh Gem Version](http://img.shields.io/gem/v/lita-locker.svg)](https://rubygems.org/gems/lita-locker)
[![Coveralls Coverage](https://img.shields.io/coveralls/esigler/lita-locker/master.svg)](https://coveralls.io/r/esigler/lita-locker)
[![Code Climate](https://img.shields.io/codeclimate/github/esigler/lita-locker.svg)](https://codeclimate.com/github/esigler/lita-locker)
[![Gemnasium](https://img.shields.io/gemnasium/esigler/lita-locker.svg)](https://gemnasium.com/esigler/lita-locker)

Locking, unlocking shared resource handler for [lita.io](https://github.com/jimmycuadra/lita).

## Installation

Add lita-locker to your Lita instance's Gemfile:

``` ruby
gem "lita-locker"
```

## Configuration

### Optional attributes

* `per_page` - The number of items to show at once when listing labels or resources. Default: 10

### Example

``` ruby
Lita.configure do |config|
  config.handlers.locker.per_page = 3
```

## Usage

lita-locker allows you to define resources (such as a server, or Git repo),
and labels (such as "production").  Labels can have multiple resources, and
resources can be referenced by multiple labels.  A label can only be locked
if all of the resources it uses are available.

### Examples
```
lock web                - Make something unavailable to others
unlock web              - Make something available to others
steal web               - Make yourself the owner of something locked by someone else
locker status web       - Show the current state of web
```

### Locking, Unlocking, State
```
lock <label>                  - A basic reservation, with no time limit. Can have # comments afterwards.
unlock <label>                - Remove a reservation.  This can only be done by whomever made the request. Can have # comments afterwards.
steal <label>                 - Force removal of a reservation.  This can be done by anyone. Can have # comments afterwards.
locker give <label> to <user> - Transfer ownership of a lock to another user.  This can only be done by the lock's current owner. Can have # comments afterwards.
```

### Status
```
locker status <label or resource>  - Show the current state of <label or resource>
locker list <username>             - Show what locks a user currently holds
locker log <label>                 - Show up to the last 10 activity log entries for <label>
locker observe <label>             - Get a notification when <label> becomes available
locker unobserve <label>           - Stop getting notifications when <label> becomes available
```

### Queueing
```
lock <label>           - If <label> is already locked, adds you to a FIFO queue of pending reservations for <label>
locker dequeue <label> - Remove yourself from the queue for <label>
```

### Labels
```
locker label list [--page N]               - List all labels
locker label create <name>                 - Create a label with <name>.
locker label delete <name>                 - Delete the label with <name>.  Clears all locks associated.
locker label add <resource> to <name>      - Adds <resource> to the list of things to lock/unlock for <name>
locker label remove <resource> from <name> - Removes <resource> from <name>
locker label show <name>                   - Show all resources for <name>
```

### Resources
```
locker resource list [--page N]   - List all resources
locker resource create <name>     - Create a resource with <name>.  (Restricted to locker_admins group)
locker resource delete <name>     - Delete the resource with <name>.  Clears all locks associated.  (Restricted to locker_admins group)
locker resource show <name>       - Show the state of <name>
```

### HTTP access
```
curl http://lita.example.com/locker/label/<name>    - Get current <name> status
curl http://lita.example.com/locker/resource/<name> - Get current <name> status
```

## License

[MIT](http://opensource.org/licenses/MIT)
