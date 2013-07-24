
require 'fileutils'
require 'open3'
require 'logger'
require 'models/configuration'

module CodinBot
	class Environment
		
		def initialize(&block)
			@config = Configuration::Environment.new
			instance_eval &block if block_given?
		end

		def configure(&block)
			yield(@config) if block_given?
		end

		#
		# SVN Functions
		#

		def repo_dir
			@config.repo_dir
		end

		def revert(username, password)
			at_revision = -1

			command = "svn sw --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"#{@config.repo_url} #{@config.repo_dir}"

			output, proc = Open3.capture2e(command)

			if output =~ /.*authorization failed.*/i
				raise 'Authorization failed'
			end

			if output =~ /.*revision.*\s([0-9]+)\./i
				at_revision = output.scan(/.*revision.*\s([0-9]+)\./i).last[0]
			end

			if proc.exitstatus != 0
				raise 'Unknown error'
			end

			at_revision.to_s
		end

		def checkout(username, password, revision)
			at_revision = -1

			revision ||= "'HEAD'"

			command = "svn checkout --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"--revision #{revision} " <<
				"#{@config.repo_url} #{@config.repo_dir}"

			puts command
			output, proc = Open3.capture2e(command)

			if output =~ /.*authorization failed.*/i
				raise 'Authorization failed'
			end

			if (output =~ /.*revision.*\s([0-9]+)\./i)
				at_revision = output.scan(/.*revision.*\s([0-9]+)\./i).last[0]
			end

			puts output

			if proc.exitstatus != 0
				raise 'Unknown error'
			end

			at_revision.to_s
		end

		def remove
			FileUtils.rm_r File.join('.', @config.repo_dir)
		end

		#
		# Build & Deploy
		#

		def build
			command = "ant cleanall deploy"

			if not File.directory?(@config.local_deploy_dir)
				FileUtils.mkdir_p @config.local_deploy_dir
			end

			output, proc = Open3.capture2e(@config.build_env, command,
				{ :chdir => File.join(@config.repo_dir, @config.base_project) })

			if proc.exitstatus != 0
				raise 'Build failed'
			end

			FileUtils.cp_r File.join(@config.repo_dir, @config.base_project,
				'build', @config.package), @config.local_deploy_dir

			@config.contexts.each do |k, c|
				`unzip -q #{File.join(@config.local_deploy_dir, @config.package)} \
				-d /tmp/build-#{c[:context]}`

				raise "Build failed" if $? != 0

				Dir.chdir "/tmp/build-#{c[:context]}" do
					xml = File.read('META-INF/application.xml')
					xml.gsub! /<context-root>.*<\/context-root>/i,
						"<context-root>#{c[:context]}<\/context-root>"
					
					File.open('META-INF/application.xml', 'w') do |file|
						file.puts xml
					end

					`zip -q -r ../#{c[:package]} . -i *`

					raise "Build failed" if $? != 0

				end # Dir.chdir

				FileUtils.cp_r File.join('/tmp', c[:package]), @config.local_deploy_dir

				FileUtils.rm_r "/tmp/build-#{c[:context]}"
				FileUtils.rm_r "/tmp/#{c[:package]}"
			end # contexts.each
		end

		def deploy(username, password, *environment)
			exitstatus = -1

			environment = environment[0] || @config

			Open3.popen2e("smbclient #{environment.deploy_server} -U sof/#{username}%#{password}",
				:chdir => environment.local_deploy_dir) do |i, o, w|
				
				i.puts "PUT #{environment.package} #{environment.remote_deploy_dir}\\#{environment.package}"
				environment.contexts.each do |k, c|
					i.puts "PUT #{c[:package]}\\#{c[:remote_deploy_dir]}\\#{c[:package]}"
				end
				i.close

				exitstatus = w.value
			end

			raise 'Deploy failed' if exitstatus != 0
		end
	end # class
end # module