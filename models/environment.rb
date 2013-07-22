
require 'fileutils'
require 'open4'

module CodinBot
	class Environment
		
		attr_accessor :description

		attr_accessor :repo_url
		attr_accessor :repo_dir
		
		attr_accessor :base_project
		attr_accessor :package
		attr_accessor :contexts

		attr_accessor :deploy_server
		attr_accessor :remote_deploy_dir
		attr_accessor :local_deploy_dir

		#
		# SVN Functions
		#

		def revert(username, password)
			at_revision = -1

			command = "svn sw --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"#{@repo_url} #{@repo_dir}"

			proc = Open4::popen4(command) do |pid, stdin, stdout, stderr|
				line = stdout.read.strip
				if (line =~ /.*revision.*\s([0-9]+)\./i)
					at_revision = line.scan(/.*revision.*\s([0-9]+)\./i).last[0]
				end
			end

			if proc.exitstatus != 0
				raise 'Revert process exited abnormaly'
			end

			at_revision.to_s
		end

		def checkout(username, password, *revision)
			at_revision = -1

			revision[0] ||= "'HEAD'"

			command = "svn checkout --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"--revision #{revision[0]} " <<
				"#{@repo_url} #{@repo_dir}"

			puts "hello2"

			proc = Open4::popen4(command) do |pid, stdin, stdout, stderr|
				line = stdout.read.strip
				if (line =~ /.*revision.*\s([0-9]+)\./i)
					at_revision = line.scan(/.*revision.*\s([0-9]+)\./i).last[0]
				end

				puts "hello"
				puts stderr.read.strip
			end

			if proc.exitstatus != 0
				raise 'Checkout process exited abnormaly'
			end

			at_revision.to_s
		end

		def remove
			FileUtils.rm_r File.join('.', @repo_dir)
		end

		#
		# Build & Deploy
		#

		def build(username, password)
			command = "ant cleanall deploy"

			Dir.chdir File.join(@repo_dir, @base_project) do
				proc = Open4::popen4(command) {}

				if proc.exitstatus != 0
					raise 'Build failed'
				end

				@contexts.each do |k, c|
					`unzip -q #{@package} -d /tmp/build-#{c[:context]}`

					raise "Build failed" if $? != 0

					Dir.chdir "/tmp/build-#{c[:context]}" do
						xml = File.read(File.join(@base_project,
							'EarContent/META-INF/application.xml'))
						xml.gsub! /<context-root>.*<\/context-root>/i,
							"<context-root>#{c[:context]}<\/context-root>"
						
						File.open(File.join(@base_project,
							'EarContent/META-INF/application.xml'), 'w') do |file|
							file.puts xml
						end

						`zip -q -r ../#{c[:package]} . -i *`

						raise "Build failed" if $? != 0

					end # Dir.chdir

					FileUtils.cp_r File.join('/tmp', c.package), @local_deploy_dir

					FileUtils.rm_r "/tmp/build-#{c[:context]}"
					FileUtils.rm_r "/tmp/#{c[:package]}"
				end # contexts.each
			end # Dir.chdir

		end

		def deploy(username, password, svn_password)
		end

	end # class
end # module