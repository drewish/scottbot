# Scottbot

Play a Scott Adams style adventure game via Slack.

## Installation

```
git clone https://github.com/drewish/scottbot.git
cd scottbot
bundle install
```

Create a [new bot configuration](https://my.slack.com/services/new/bot) and make a note of the API key.


## Usage

Replace the `game.sao` file with one of your choice then start up the app:

```bash
SLACK_API_TOKEN=xoxb-XXXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXXXX bundle exec ruby ./scottbot.rb
```
