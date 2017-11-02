# Scottbot

Play a Scott Adams style adventure game via Slack. Scottbot uses the awesome [Scottkit gem](https://github.com/MikeTaylor/scottkit) to play the games.

## Installation

Assuming you've got Ruby 2.0+ and [Bundler](http://bundler.io/) installed all you need to do is:

```
git clone https://github.com/drewish/scottbot.git
cd scottbot
bundle install
```

## Usage

Create a [new bot configuration](https://my.slack.com/services/new/bot) and make a note of the API Token.

This library includes a dummy `game.sao` file but you'll probably want to replace it with something else.

Set the API Token in the `SLACK_API_TOKEN` environment variable and start up the app:

```bash
SLACK_API_TOKEN=xoxb-XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX bundle exec ruby ./scottbot.rb
```

It will connect to your team and then you can send the bot a direct message to play.
