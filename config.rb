
require 'configatron'

configatron.options.log_output = true
configatron.options.dir_mode = 'normal'
configatron.options.dir = 'pid'

configatron.server.addr = '10.209.67.21'
configatron.server.port = 6667
configatron.server.nick = 'Marmota'
configatron.server.messages_per_second = 30
configatron.server.channels = ['#testchan']

configatron.plugins.plugins = [CodinBot::SVNCommands]

configatron.plugins.options = {}
configatron.plugins.options[CodinBot::SVNCommands] = {
	:trunk => {
		:url => 'http://10.209.64.205/getec/SIOP/trunk/04_Implementacao',
		:dir => 'repos/trunk'
	}
}