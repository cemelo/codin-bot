module Cinch::Helpers
	def Format(*args)
		lines = args.last
		args.pop

		@message = ''
		
		if not lines.nil?
			lines.split("\n").each do |line|
				args.push line.strip
				@message << Cinch::Formatting.format(*args) << "\n"
				args.pop
			end
		end

		@message.strip!
	end
end

module CodinBot
	require 'lib/plugins/common_commands'
	require 'lib/plugins/svn_commands'
	require 'lib/plugins/build_commands'
	require 'lib/plugins/fortune'
end