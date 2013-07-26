
require 'fileutils'
require 'open3'
require 'logger'
require 'date'
require 'thread'

require 'models/configuration'
require 'models/errors'

module CodinBot
	class Environment

		attr_reader :config

		attr_accessor :monitoring_thread

		def initialize(&block)
			@config = Configuration::Environment.new
			@lock = Mutex.new
			@locking_user = nil

			instance_eval &block if block_given?
		end

		def configure(&block)
			yield(@config) if block_given?

			if @config.log_file
				@logger = Logger.new @config.log_file, 'daily'
				@logger.formatter = proc do |sev, datetime, progname, msg|
					"#{sev} #{datetime} #{progname}:\n#{msg}"
				end
			end
		end

		def locking_user
			@locking_user
		end

		def lock(user)
			result = false

			@lock.synchronize do
				if @locking_user.nil?
					@locking_user = user
					result = true
				else
					result = false
				end
			end

			result
		end

		def unlock
			@lock.synchronize do
				@locking_user = nil
			end

			@locking_user.nil?
		end

		def log
			if not @logger
				@logger = Logger.new STDOUT
			end

			@logger
		end

		def log?
			not @logger.nil? and File.exists? log_file
		end

		def log_file
			@config.log_file
		end

		#
		# SVN Functions
		#

		def checked_out?
			File.directory? @config.repo_dir
		end

		def revert(username, password)
			at_revision = -1

			command = "svn sw --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"#{@config.repo_url} #{@config.repo_dir}"

			output, proc = Open3.capture2e(command)

			log.info output

			if output =~ /.*authorization failed.*/i
				raise SVNAuthorizationError.new 'Authorization failed'
			end

			if output =~ /.*revision.*\s([0-9]+)\./i
				at_revision = output.scan(/.*revision.*\s([0-9]+)\./i).last[0]
			end

			if proc.exitstatus != 0
				raise SVNError.new 'Revert error'
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

			output, proc = Open3.capture2e(command)

			log.info output

			if output =~ /.*authorization failed.*/i
				raise SVNAuthorizationError.new 'Authorization failed'
			end

			if (output =~ /.*revision.*\s([0-9]+)\./i)
				at_revision = output.scan(/.*revision.*\s([0-9]+)\./i).last[0]
			end

			if proc.exitstatus != 0
				raise SVNError.new 'Checkout error'
			end

			at_revision.to_s
		end

		def remove
			begin
				FileUtils.rm_r File.join('.', @config.repo_dir)
			rescue
				raise SVNError.new 'Directory does not exist'
			end
		end

		def last_log(username, password)
			output = `svn log -l 1 --username #{username} \
				--password #{password} #{@config.repo_url}`

			if $? != 0
				if output =~ /.*authorization failed.*/i
					raise SVNAuthorizationError.new 'Authorization failed'
				else
					raise SVNError.new 'Log error'
				end
			end

			matches = /
						^-{72}\n 									# First line
						r([0-9]+) [ ] \| 					# Revision
						[ ] ([[:graph:]]+) [ ] \|	# Author
						[ ] (.+) [ ]  \|					# DateTime
						[ ] [0-9]+ [ ]line[s]?		# Message line count
						\n\n(.*)\n 								# Commit Message
						-{72}$/xm.match(output)

			revision = matches[1].to_i
			author   = matches[2]
			datetime = DateTime.parse(matches[3])
			message  = matches[4]

			return revision, author, datetime, message
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

			log.info output

			if proc.exitstatus != 0
				raise BuildError.new 'Build failed'
			end

			FileUtils.cp_r File.join(@config.repo_dir, @config.base_project,
				'build', @config.package), @config.local_deploy_dir

			@config.contexts.each do |k, c|
				log.info `unzip -o -q #{File.join(@config.local_deploy_dir, @config.package)} \
				-d /tmp/build-#{c[:context]}`

				raise BuildError.new "Build failed" if $? != 0

				Dir.chdir "/tmp/build-#{c[:context]}" do
					xml = File.read('META-INF/application.xml')
					xml.gsub! /<context-root>.*<\/context-root>/i,
						"<context-root>#{c[:context]}<\/context-root>"
					
					File.open('META-INF/application.xml', 'w') do |file|
						file.puts xml
					end

					log.info `zip -q -r ../#{c[:package]} . -i *`

					raise BuildError.new "Build failed" if $? != 0

				end # Dir.chdir

				FileUtils.cp_r File.join('/tmp', c[:package]), @config.local_deploy_dir

				FileUtils.rm_r "/tmp/build-#{c[:context]}"
				FileUtils.rm_r "/tmp/#{c[:package]}"
			end # contexts.each
		end

		def deploy(username, password, *package)
			exitstatus = -1

			Open3.popen2e("smbclient #{@config.deploy_server} -U sof/#{username}%#{password}",
				:chdir => @config.local_deploy_dir) do |i, oe, w|
				
				if package.length > 0
					i.puts "PUT #{package[0]} #{@config.remote_deploy_dir}\\#{package[0]}"
				else
					i.puts "PUT #{@config.package} #{@config.remote_deploy_dir}\\#{@config.package}"
					@config.contexts.each do |k, c|
						i.puts "PUT #{c[:package]}\\#{c[:remote_deploy_dir]}\\#{c[:package]}"
					end
				end

				i.close

				output = ""
				oe.each do |line|
					output << line
				end

				log.info output

				exitstatus = w.value
			end

			raise DeployError.new 'Deploy failed' if exitstatus != 0
		end
	end # class
end # module