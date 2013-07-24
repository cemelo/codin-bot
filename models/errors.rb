
module CodinBot
	class SVNError < RuntimeError
	end

	class SVNAuthorizationError < RuntimeError
	end

	class BuildError < RuntimeError
	end

	class DeployError < RuntimeError
	end
end