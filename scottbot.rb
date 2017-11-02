#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'slack-ruby-client'
require 'scottkit/game'

# Make a couple changes to the ScottKit game... we ignore the play method's loop
# and call all its methods from inside the slack callbacks.
class MyGame < ScottKit::Game
  # Grab all the output and reset the buffer.
  def grab_output
    string = output.string
    output.reopen('')
    string
  end
end

unless ENV['SLACK_API_TOKEN']
  fail "Must provde a Slack API token in the SLACK_API_TOKEN environment variable"
end

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

client = Slack::RealTime::Client.new
# TODO: should probably be locking this to prevent race conditions
@games_by_channel = {}

def start_game
  file_name = 'game.sao'
  game = MyGame.new(output: StringIO.new, no_wait: true)
  game.load(IO.read(file_name))
  game.decompile(StringIO.new)
  game.prepare_to_play
  game.prompt_for_turn
  game
end

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."

  # TODO: restore games?
end

client.on :message do |data|
  # require 'pry'; binding.pry
  # puts data.inspect

  case data.channel[0]
  when 'C' # Group
    if data.text =~ /play .*?game/
      client.message channel: data.channel, text: "DM me if you want to play"
    end
  when 'D' # Direct
    if @games_by_channel[data.channel] && !@games_by_channel[data.channel].finished?
      game = @games_by_channel[data.channel]
      client.typing channel: data.channel

      game.process_turn(data.text)
      game.prompt_for_turn unless game.finished?
      client.message channel: data.channel, text: game.grab_output
    else
      game = @games_by_channel[data.channel] = start_game
      client.message channel: data.channel, text: game.grab_output
    end
  end
end

client.on :close do |_data|
  puts "Client is about to disconnect"
  # TODO: save games?
end

client.on :closed do |_data|
  puts "Client has disconnected successfully!"
end

client.start_async

loop do
  Thread.pass
end
