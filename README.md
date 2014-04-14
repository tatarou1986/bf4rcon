# Bf4rcon

EA Battlefield 4 RCON Protocol implemented in Ruby 2.0.0.

You wants Rails web applications relating to BattleField4?
RubyBf4ron is better choice for it!

## Installation

Add this line to your application's Gemfile:

    gem 'bf4rcon'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bf4rcon

## Usage
Example of listing server states

```ruby:showstate.rb
require 'bf4rcon'

HOST = "192.168.1.1"
PORT = 25615
PASSWORD = "passwd"

s = Bf4Rcon.open(HOST, PORT, PASSWORD){|bf4srv|
  ## Executing serverInfo command
  p bf4srv.bf4_serverInfo.response
}
```

Method prefix `bf4_` effects to recognize a sentence below the under bar as a command of Battle Field 4 RCON protocol. So, `bf4_serverInfo` method has same effect of entering `serverInfo` on your BF4 server. `response` method returns a server response as its name suggests.

Example of executing a command that has multiple arguments such as punk buster commands

```ruby:pbsvplist.rb
require 'bf4rcon'

HOST = "192.168.1.1"
PORT = 25615
PASSWORD = "passwd"

s = Bf4Rcon.open(HOST, PORT, PASSWORD){|bf4srv|
  ## Executing a punkBuster command
  bf4srv.bf4_punkBuster__pb_sv_command "pb_sv_plist"
}
```

Some RCON commands consist of multiple arguments, which are separated by periods such as punkBuster command.  As stated above, `bf4_punkBuster__pb_sv_command "pb_sv_plist"` has same effects of entering `punkBuster.pb_sv_command "pb_sv_plist"` on your BF4 server.  As you can see, the double under bar is recognized as a period. So, you want to execute a RCON command `admin.say "hello"` you can simply write `bf4srv.bf4_admin__say "hello"`.

Example of the chat observer that executes the yell command when specific users say something

```ruby:chatbot.rb
require 'bf4rcon'

HOST = "192.168.1.1"
PORT = 25615
PASSWORD = "passwd"

s = Bf4Rcon.open(HOST, PORT, PASSWORD){|bf4srv|
  while true
    r = bf4srv.wait_event
    if r.response[0] == "player.onChat" and 
        (r.response[1] == "John" or
         r.response[1] == "Michael")
      p r.response
      if match = /^yell\s(.*$)/.match(r.response[2])
        puts "#{r.response[1]} yell #{match[1]}"
        p bf4srv.bf4_admin__say(match[1], "all")
      end
    end
    r.response
  end
}
```

When players John and Michael say something in the game, this script echos their words as the yell from server administrator. As you can see, `bf4srv.wait_event` is blocking until the server returns an action.

## Contributing

1. Fork it ( http://github.com/<my-github-username>/bf4rcon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

