
require 'configatron'
require 'models/environment'

integracao = CodinBot::Environment.new do
	configure do |config|
		config.description = 'Ambiente de Integração'
		config.repo_url = 'http://10.209.64.205/getec/SIOP/trunk/04_Implementacao'
		config.repo_dir = 'repos/trunk'
		config.base_project = 'SiopEAR'
		config.package = 'SiopEAR.ear'
		config.deploy_server = '\\\\\\\\10.209.64.48\\\\siop'
		config.remote_deploy_dir = 'deploy\\Testes_integracao\\siop'
		config.local_deploy_dir = 'build'

		config.contexts = {
			:acesso_publico => {
				:context => 'publico',
				:package => 'SiopPublico.ear',
				:remote_deploy_dir => 'deploy\\Testes_integracao\\acesso_publico'
			},
			:relatorios => {
				:context => 'relatorios',
				:package => 'SiopRelatorios.ear',
				:remote_deploy_dir => 'deploy\\Testes_integracao\\relatorios'
			}
		}

		config.build_env = {
			'JBOSS_HOME' => '/Users/carlos/Documents/apps/jboss-4.2.3.GA'
		}
	end
end

configatron.options.log_output = true
configatron.options.dir_mode = 'normal'
configatron.options.dir = 'pid'

configatron.server.addr = '10.209.67.21'
configatron.server.port = 6667
configatron.server.nick = 'Marmota'
configatron.server.messages_per_second = 30
configatron.server.channels = ['#testchan']

#
# Plugins Configurations
#

configatron.plugins.plugins = [CodinBot::SVNCommands]
configatron.plugins.options = {}
	
# SVN Branches
configatron.plugins.options[CodinBot::SVNCommands] = {
	:trunk => integracao
}