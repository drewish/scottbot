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
# probably should be locking this
@games_by_channel = {}

def start_game
  file_name = 'game.sao'
  game = MyGame.new(output_buffer: StringIO.new)
  game.load(IO.read(file_name))
  game.decompile(StringIO.new)
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
    puts 'group'
    if data.text =~ /play .*?game/
      client.message channel: data.channel, text: "DM me if you want to play"
    end
  when 'D' # Direct
    puts 'direct'
    if @games_by_channel[data.channel] && !@games_by_channel[data.channel].finished?
      game = @games_by_channel[data.channel]
      client.typing channel: data.channel

      game.process_turn(data.text)
      client.message channel: data.channel, text: game.prompt_for_turn
    else
      game = @games_by_channel[data.channel] = start_game
      game.prepare_to_play
      client.message channel: data.channel, text: game.prompt_for_turn
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
