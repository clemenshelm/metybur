# Metybur
[![Build Status](https://travis-ci.org/clemenshelm/metybur.svg?branch=master)](https://travis-ci.org/clemenshelm/metybur)

A DDP client for Ruby to connect to Meteor apps.

Metybur lets your Ruby application connect to a Meteor app. It allows you
to subscribe to collections and to receive updates on them.
You can also call Meteor methods from Ruby.

## Installation

Add this line to your application's Gemfile:

    gem 'metybur'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install metybur

## Usage

### Connecting to a Meteor app

Metybur runs in an [EventMachine](http://eventmachine.rubyforge.org/) loop.
Therefore all our code must be wrapped in an `EM.run` block.

    require 'eventmachine'

    EM.run do
      meteor = Metybur.connect('http://my-meteor-app.org:80/websocket')
    end

will connect to your Meteor app. If you want to log in at your app, pass the credentials:

    require 'eventmachine'

    EM.run do
      meteor = Metybur.connect('http://my-meteor-app.org:80/websocket', email: 'rubyist@meteor.com', password: 'twinkle twinkle')
    end

You can also pass a `:username` or `:id` instead of an `:email`. These arguments correspond to those described in [the Meteor docs](http://docs.meteor.com/#/full/meteor_loginwithpassword).

From now on I'll skip the `EM.run` block in code examples, but don't forget about it. Otherwise it won't work! Promise!

## Contributing

1. Fork it ( https://github.com/clemenshelm/metybur/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
