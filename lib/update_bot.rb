
pid = `cat .lock 2> /dev/null`.to_i

if $? != 0
	Process.exit(1)
end

Process.kill("USR1", pid)

if $? != 0
	Process.exit(1)
end

version = `cat /tmp/bot-version`

if $? != 0
	Process.exit(1)
end

#####

require 'version'

include CodinBot

if CodinBot.version != version
	open '/tmp/bot-version', 'w' do |io|
		io.write CodinBot.version
		io.close
	end

	Process.kill("USR2", pid)
	sleep 1
	Process.kill("TERM", pid)
	exec("nohup rake")
end
