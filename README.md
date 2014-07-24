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

None

## Usage

lita-locker allows you to define resources (such as a server, or Git repo),
and labels (such as "production").  Labels can have multiple resources, and
resources can be referenced by multiple labels.  A label can only be locked
if all of the resources it uses are available.

### Examples
```
lock web                - Make something unavailable to others
lock web 30m            - Make something unavailable to others for 30 minutes
unlock web              - Make something available to others
locker reserve web      - Make yourself the next owner of something after it is unlocked
locker status web       - Show the current state of web
```

### Locking, Unlocking, State
```
lock <label>         - A basic reservation, with no time limit.
unlock <label>       - Remove a reservation.  This can only be done by whomever made the request.
steal <label>        - Force removal of a reservation.  This can be done by anyone.
```

### Time-based locking - Not implemented yet!
```
lock <subject> <time>        - A time-limited reservation.  <time> must be a number with a "s", "m", or "h" postfix.
```

### Reservations - Not implemented yet!
```
reserve <subject> - Add yourself to a FIFO queue of pending reservations for <subject>
unreserve <subject> - Remove yourself from the queue for <subject>
```

### Labels
```
locker label list                          - List all labels
locker label create <name>                 - Create a label with <name>.
locker label delete <name>                 - Delete the label with <name>.  Clears all locks associated.
locker label add <resource> to <name>      - Adds <resource> to the list of things to lock/unlock for <name>
locker label remove <resource> from <name> - Removes <resource> from <name>
locker label show <name>                   - Show all resources for <name>
```

### Resources
```
locker resource list          - List all resources
locker resource create <name> - Create a resource with <name>.  (Restricted to locker_admins group)
locker resource delete <name> - Delete the resource with <name>.  Clears all locks associated.  (Restricted to locker_admins group)
locker resource show <name>   - Show the state of <name>
```

### HTTP access
```
curl http://lita.example.com/locker/label/<name>    - Get current <name> status
curl http://lita.example.com/locker/resource/<name> - Get current <name> status
```

## License

[MIT](http://opensource.org/licenses/MIT)
