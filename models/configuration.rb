
module CodinBot
	module Configuration
		class Environment
			attr_accessor :description
			attr_accessor :svn_branch

			attr_accessor :repo_url
			attr_accessor :repo_dir
			
			attr_accessor :base_project
			attr_accessor :package
			attr_accessor :contexts
			attr_accessor :build_env

			attr_accessor :deploy_server
			attr_accessor :remote_deploy_dir
			attr_accessor :local_deploy_dir

			attr_accessor :log_file
			attr_accessor :sleep_interval
		end
	end
end