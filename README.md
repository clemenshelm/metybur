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

```ruby
require 'eventmachine'

EM.run do
  meteor = Metybur.connect('http://my-meteor-app.org:80/websocket')
end
```

will connect to your Meteor app. If you want to log in at your app, pass the credentials:

```ruby
require 'eventmachine'

EM.run do
  meteor = Metybur.connect(
    'http://my-meteor-app.org:80/websocket',
    email:    'rubyist@meteor.com',
    password: 'twinkle twinkle'
  )
end
```

You can also pass a `:username` or `:id` instead of an `:email`. These arguments correspond to those described in [the Meteor docs](http://docs.meteor.com/#/full/meteor_loginwithpassword).

Alternatively you can log in at a later point by calling the `login` method explicitly:

```ruby
require 'eventmachine'

EM.run do
  meteor = Metybur.connect('http://my-meteor-app.org:80/websocket')

  # Do something unauthenticated...

  meteor.login(user: {email: 'rubyist@meteor.com'}, password: 'twinkle twinkle'
end
```

From now on I'll skip the `EM.run` block in code examples, but don't forget about it. Otherwise it won't work! Promise!

### Subscribing to a Meteor record set

After connecting to your Meteor app, you can subscribe to one of the published record sets:

```ruby
meteor = Metybur.connect('http://my-meteor-app.org:80/websocket')
meteor.subscribe('my-chat-messages')
```

### Collections

Once you've subscribed, you will receive all records that are already in the record set. The record set contains records from one or more collections. You can process these records as they arrive:

```ruby
@chat_messages = {}
meteor.collection('chat-messages')
  .on(:added) { |id, attributes| @chat_messages[id] = attributes }
```

### Remote Procedure Calls

Call meteor methods to write back data to Meteor or to trigger actions in your Meteor app.

```ruby
meteor.post_chat_message('Hey there!', in_room: 'General')
```

This is equal to this method call in Meteor:

```javascript
// Javascript
Meteor.call('postChatMessage', { inRoom: 'General' });
```

If you prefer the Meteor syntax, you can also call the method like this:

```ruby
meteor.call('postChatMessage', inRoom: 'General')
```

Note that you have to choose this syntax, if your Meteor method name collides with a Metyrub method (like `collection` or `subscribe`).

### Logging

To debug your application, you can lower the log level to see all incoming websocket messages.

```ruby
Metybur.log_level = :debug
```

Make sure to set the log level before calling `Metybur.connect`, as it won't have any effect afterwards.

## Contributing

1. Fork it ( https://github.com/clemenshelm/metybur/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
