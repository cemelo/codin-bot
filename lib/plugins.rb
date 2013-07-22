module Cinch::Helpers
	def Format(*args)
		lines = args.last
		args.pop

		@message = ''
		
		lines.split("\n").each do |line|
			args.push line.strip
			@message << Cinch::Formatting.format(*args) << "\n"
			args.pop
		end

		@message.strip!
	end
end

module CodinBot
	require_relative 'plugins/svn_commands'
end