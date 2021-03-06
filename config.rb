
require 'configatron'

require 'models/environment'
require 'plugins'

integracao = CodinBot::Environment.new do
	configure do |config|
		config.description = 'Ambiente de Integração'
		config.svn_branch = 'trunk'

		config.repo_url = 'http://10.209.64.205/getec/SIOP/trunk/04_Implementacao'
		config.repo_dir = 'repos/trunk'
		config.base_project = 'SiopEAR'
		config.package = 'SiopEAR.ear'
		config.deploy_server = '\\\\\\\\10.209.64.48\\\\siop'
		config.remote_deploy_dir = 'Deploy\\Testes_integracao\\siop'
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
			'JBOSS_HOME' => '/opt/jboss-4.2.3.GA'
		}

		config.log_file = 'log/integracao.log'
	end
end

testes = CodinBot::Environment.new do
	configure do |config|
		config.description = 'Ambiente de Testes'
		config.svn_branch = 'testes'

		config.repo_url = 'http://10.209.64.205/getec/SIOP/branches/testes/04_Implementacao'
		config.repo_dir = 'repos/testes'
		config.base_project = 'SiopEAR'
		config.package = 'SiopEAR.ear'
		config.deploy_server = '\\\\\\\\10.209.64.48\\\\siop'
		config.remote_deploy_dir = 'Deploy\\Testes_sistema\\siop'
		config.local_deploy_dir = 'build/testes'

		config.contexts = {
			:acesso_publico => {
				:context => 'publico',
				:package => 'SiopPublico.ear',
				:remote_deploy_dir => 'deploy\\Testes_sistema\\acesso_publico'
			},
			:relatorios => {
				:context => 'relatorios',
				:package => 'SiopRelatorios.ear',
				:remote_deploy_dir => 'deploy\\Testes_sistema\\relatorios'
			}
		}

		config.build_env = {
			'JBOSS_HOME' => '/opt/jboss-4.2.3.GA'
		}

		config.log_file = 'log/testes.log'
	end
end

producao = CodinBot::Environment.new do
	configure do |config|
		config.description = 'Ambiente de Produção'
		config.svn_branch = 'producao'

		config.repo_url = 'http://10.209.64.205/getec/SIOP/branches/producao/04_Implementacao'
		config.repo_dir = 'repos/producao'
		config.base_project = 'SiopEAR'
		config.package = 'SiopEAR.ear'
		config.deploy_server = '\\\\\\\\10.209.64.48\\\\siop'
		config.remote_deploy_dir = 'Deploy\\Producao'
		config.local_deploy_dir = 'build/producao'

		config.contexts = {
			:acesso_publico => {
				:context => 'publico',
				:package => 'SiopPublico.ear',
				:remote_deploy_dir => 'deploy\\Producao_acesso_publico'
			},
			:relatorios => {
				:context => 'relatorios',
				:package => 'SiopRelatorios.ear',
				:remote_deploy_dir => 'deploy\\Relatorios'
			}
		}

		config.build_env = {
			'JBOSS_HOME' => '/opt/jboss-4.2.3.GA'
		}

		config.log_file = 'log/producao.log'
	end
end

configatron.options.log_output = true
configatron.options.dir_mode = 'normal'
configatron.options.dir = 'pid'

configatron.server.addr = '10.209.67.21'
configatron.server.port = 6667
configatron.server.nick = 'Marmota'
configatron.server.messages_per_second = 50
configatron.server.channels = ['#codin']

#
# Environment Configurations
#

configatron.shared = {
	:environments => {
		:integracao => integracao,
		:testes => testes,
		:producao => producao
	},

	:auth => {}
}

#
# Plugins Configurations
#

configatron.plugins.plugins = [
	CodinBot::CommonCommands,
	CodinBot::SVNCommands,
	CodinBot::BuildCommands,
	CodinBot::Fortune
]
configatron.plugins.options = {}
	
# SVN Branches
configatron.plugins.options[CodinBot::SVNCommands] = {
	:monitor_sleep_interval => 5
}

configatron.plugins.options[CodinBot::SVNCommands] = {
	:command => "fortune"
}