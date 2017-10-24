require 'slack-ruby-client'
require 'scottkit/game'

# The game sends it output to stdout but we just capture the strings in a buffer
# and pull them out as chunks which we send in a single message. We ignore the
# play method since it blocks on `gets` and just call some methods directly.
class MyGame < ScottKit::Game
  attr_reader :output_buffer

  def initialize(options)
    @output_buffer = StringIO.new
    super
  end

  def puts *args
    output_buffer.puts *args
  end

  def print *args
    output_buffer.print *args
  end

  # Grab all the output and reset the buffer
  def prompt_for_turn
    super

    string = output_buffer.string
    output_buffer.reopen('')
    string
  end
end

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
  config.logger = Logger.new(STDOUT)
  config.logger.level = Logger::INFO
end

client = Slack::RealTime::Client.new
channel = nil

file_name = 'game.sao'
game = MyGame.new(output_buffer: StringIO.new)
game.load(IO.read(file_name))
game.decompile(StringIO.new)

client.on :hello do
  puts "Successfully connected, welcome '#{client.self.name}' to the '#{client.team.name}' team at https://#{client.team.domain}.slack.com."

  # Limit the conversation to one channel for now
  channel = client.channels.values.find { |c| c.name == 'bots' }

  game.prepare_to_play
  client.message channel: channel['id'], text: game.prompt_for_turn
end

client.on :message do |data|
  next if data.channel != channel['id']
  # TODO: Figure out what do do about starting a new game
  next if game.finished?

  client.typing channel: data.channel

  game.process_turn(data.text)
  client.message channel: data.channel, text: game.prompt_for_turn
end

client.on :close do |_data|
  puts "Client is about to disconnect"
end

client.on :closed do |_data|
  puts "Client has disconnected successfully!"
end

client.start_async

loop do
  Thread.pass
end
