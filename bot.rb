
require 'cinch'
require 'fileutils'

require 'config'
require 'version'

include CodinBot

bot = Cinch::Bot.new do
  configure do |config|
    config.server = configatron.server.addr
    config.channels = configatron.server.channels
    config.nick = configatron.server.nick
    config.messages_per_second = configatron.server.messages_per_second
    config.encoding = 'UTF-8'

    config.plugins.plugins = configatron.plugins.plugins
    config.plugins.options = configatron.plugins.options

    config.shared = configatron.shared
  end  

  trap "SIGUSR1" do
    FileUtils.rm '/tmp/bot-version' if File.exists? '/tmp/bot-version'
    open '/tmp/bot-version', 'w' do |io|
      io.write CodinBot.version
      io.close
    end
  end

  trap "SIGUSR2" do
    Thread.new do
      bot.channels.each do |channel|
        version = `cat /tmp/bot-version`
        channel.msg Format(:grey,
        "%s! Versão do bot atualizada para %s." %
        [Format(:bold, :red, "Atenção"),
          Format(:bold, :red, version)]), true
      end
    end
  end

  trap "SIGTERM" do
    Thread.new do
      FileUtils.rm '.lock'
      bot.quit
    end
  end

  trap "SIGINT" do
    Thread.new do
      FileUtils.rm '.lock'
      bot.quit
    end
  end

  on :join do |m|
    m.reply Format(:grey,
      "Olá %s! Para conhecer os comandos suportados, digite %s." %
      [Format(:bold, :blue, m.user.nick),
        Format(:bold, :blue, "!ajuda")]) if m.user.nick != bot.nick
  end
end

open '.lock', 'w' do |io|
  io.write(Process.pid)
end

# bot.loggers.level = :warn
bot.start