require "cinch"

module CodinBot
  class Fortune
    include Cinch::Plugin

    match /fortune/i

    def execute(m)
      m.reply [m.user.nick, fortune].join(":\n")
    end

    private

    def fortune
      command = config[:command] || "fortune"
      max_length = config[:max_length] || 256
      fortune = `#{command} -n #{max_length} -s`
      fortune
    end

    def sanitize_fortune(fortune)
      fortune.gsub(/[\t]/, "    ")
    end

  end
end