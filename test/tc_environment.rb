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
				:package => 'SiopEAR-publico.ear'
			}
		}
	end

	def test_checkout
		@environment.checkout('eduribeiro', 'CreweP8wresp')
		assert_equal(true, File.directory?(@environment.repo_dir))
	end

	def teardown
		begin
			FileUtils.rm_r @environment.repo_dir
		rescue
		end
	end

end