require 'models/environment'

class TestEnvironment < Test::Unit::TestCase
	
	def setup
		@environment = CodinBot::Environment.new
		@environment.repo_url = 'http://10.209.64.205/getec/SIOP/trunk/04_Implementacao'
		@environment.repo_dir = 'repos/test/trunk'
		
		@environment.base_project = 'SiopEAR'
		@environment.package = 'SiopEAR.ear'
		@environment.contexts = {
			:acesso_publico => {
				:context => 'acessopublico',
				:package => 'SiopEAR-publico.ear',
				:remote_deploy_dir => 'Testes_integracao\\acessopublico'
			}
		}

		@environment.deploy_server = '\\\\\\\\10.209.64.48\\\\siop'
		@environment.local_deploy_dir = 'build/'
		@environment.remote_deploy_dir = 'Testes_integracao\\siop'

		@environment.build_env = {
			"JBOSS_HOME" => "/Users/carlos/Documents/dev/apps/jboss-4.2.3.GA"
		}
	end

	def test_build
		@environment.checkout('eduribeiro', 'CreweP8wresp')
		assert_equal(true, File.directory?(@environment.repo_dir))

		@environment.build
		assert_equal(true, File.exists?(
			File.join(@environment.local_deploy_dir, @environment.package)))

		@environment.deploy('eduribeiro', 'CreweP8wresp')
	end

	def teardown
		# begin
		# 	FileUtils.rm_r 'repos/test'
		# rescue
		# end
	end

end