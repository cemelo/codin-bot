require 'cinch'
require 'fileutils'
require 'open4'

module CodinBot
	module SVN
		include Cinch::Helpers

		def Remove(dir)
			FileUtils.rm_r File.join('.', dir)
		end

		def Revert(url, dir, username, password)
			@revision = -1
			@command = "svn sw --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"#{url} #{dir}"

			proc = Open4::popen4(@command) do |pid, stdin, stdout, stderr|
				line = stdout.read.strip
				if (line =~ /.*revision.*\s([0-9]+)\./i)
					@revision = line.scan(/.*revision.*\s([0-9]+)\./i).last[0]
				end
				
				debug stderr.read.strip
			end

			if proc.exitstatus != 0
				raise 'Revert process exited abnormaly'
			end

			@revision.to_s
		end

		def Checkout(url, dir, username, password, *revision)
			@revision = 0
			@command = "svn checkout --non-interactive --force " <<
				"--username #{username} --password #{password} " <<
				"--revision #{revision} " <<
				"#{url} #{dir}"

			revision = "'HEAD'" if not revision

			proc = Open4::popen4(@command) do |pid, stdin, stdout, stderr|
				line = stdout.read.strip
				if (line =~ /.*revision.*\s([0-9]+)\./i)
					@revision = line.scan(/.*revision.*\s([0-9]+)\./i).last[0]
				end

				debug stderr.read.strip
			end

			if (proc.exitstatus != 0)
				raise 'Checkout process exited abnormaly'
			end
				
			@revision.to_s
		end
	end
end