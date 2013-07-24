
require 'cinch'
require 'lib/plugins'

require 'config'

# def Format(*args)
#   lines = args.last
#   args.pop

#   @message = ''
  
#   lines.split("\n").each do |line|
#     args.push line.strip
#     @message << Cinch::Formatting.format(*args) << "\n"
#     args.pop
#   end

#   @message.strip!
# end

bot = Cinch::Bot.new do
  configure do |config|
    config.server = configatron.server.addr
    config.channels = configatron.server.channels
    config.nick = configatron.server.nick
    config.messages_per_second = configatron.server.messages_per_second
    config.encoding = 'UTF-8'

    config.plugins.plugins = configatron.plugins.plugins
    config.plugins.options = configatron.plugins.options
  end  

  trap "SIGINT" do
    bot.quit
  end

  on :join do |m|
    m.reply Format(:grey,
      "Olá %s! Para conhecer os comandos suportados, digite %s." %
      [Format(:bold, :blue, m.user.nick),
        Format(:bold, :blue, "!ajuda")]) if m.user.nick != bot.nick
  end
end

bot.loggers.level = :warn
bot.start
