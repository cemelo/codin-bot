
$LOAD_PATH.unshift(File.expand_path(__dir__))
$LOAD_PATH.unshift(File.join(File.expand_path(__dir__), 'lib'))

# desc "Test"
# task :test => [] do
# 	require 'test/unit'
# 	require 'test/tc_environment'
# end

desc "Run the bot"
task :default => [] do
	require 'bot'
end

desc "Get the bot version"
task :version => [] do
	require 'version'
	include CodinBot
	
	puts CodinBot.version
end

task :update => [] do
	require 'update_bot'
end