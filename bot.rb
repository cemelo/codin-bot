
require 'cinch'
require 'lib/plugins'

require 'config'

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
end

bot.loggers.level = :warn
bot.start
