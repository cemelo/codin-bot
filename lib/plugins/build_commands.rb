require 'cinch'

require 'models/errors'

class CodinBot::BuildCommands
	include Cinch::Plugin
	
	match /build ajuda$/i, :method => :help
	match /build ajuda(?:[ ]([[:graph:]]+))$/ix, :method => :help_command

	match /build[ ]compilar[ ]?
		((?<=compilar[ ])[[:graph:]]+)?
		(?<![ ])$/ix, :method => :build

	match /build[ ]implantar[ ]?
		([[:graph:]]+)?
		(?:[ ]em[ ]([[:graph:]]+))?
		(?<![ ])$/ix, :method => :deploy

	def lock_env(user, target)
		return shared[:environments][target.to_sym].lock user
	end

	def unlock_env(target)
		shared[:environments][target.to_sym].unlock
	end

	def build(m, target)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!build compilar <ambiente>")) if target.nil?

		return m.reply Format(:grey, "%s! Ambiente em uso por %s." % [
			Format(:bold, :red, "ERRO"),
			Format(:bold, :blue, shared[:environments][target.to_sym].locking_user)
		]) unless lock_env m.user.nick, target

		if not shared[:auth][m.user.nick]
			return m.reply Format(:grey,
				"Este comando exige autenticação. Para autenticar-se,\ndigite %s" %
				Format(:bold, "/msg #{bot.nick} !autenticar \"<senha>\" \"[<senha_svn>]\""))
		end

		return m.reply Format(:grey, "Ambiente não %s existe." %
			Format(:bold, :blue, target)) if shared[:environments][target.to_sym].nil?

		password = shared[:auth][m.user.nick][:password]
		revision = 0

		begin
			if shared[:environments][target.to_sym].checked_out?
				m.reply Format(:grey, "Revertendo alterações no código-fonte.")
				revision = shared[:environments][target.to_sym].revert(m.user.nick, password)
			else
				m.reply Format(:grey, "Criando cópia local do código-fonte.")
				revision = shared[:environments][target.to_sym].checkout(m.user.nick, password, "'HEAD'")
			end
			
			m.reply Format(:grey, "Compilando revisao %s do ambiente %s." %
				[Format(:bold, :blue, revision), Format(:bold, :blue, target)])

			shared[:environments][target.to_sym].build

			m.reply Format(:grey, "Ambiente %s compilado com sucesso." %
				Format(:bold, :blue, target)), true
		rescue CodinBot::SVNError => s
			m.reply Format(:grey,
				"%s! falha ao atualizar o código do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)]), true
		rescue CodinBot::BuildError => b
			m.reply Format(:grey,
				"%s! falha ao compilar código do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)]), true
		end

		unlock_env target
	end

	def deploy(m, target, deploy_env)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!build implantar <ambiente> [em <ambiente>]")) \
			if target.nil?

		return m.reply Format(:grey, "%s: Ambiente em uso por %s." % [
			Format(:bold, :red, "ERRO"),
			Format(:bold, :blue, shared[:environments][target.to_sym].locking_user)
		]) unless lock_env m.user.nick, target

		if not shared[:auth][m.user.nick]
			return m.reply Format(:grey,
				"Este comando exige autenticação. Para autenticar-se,\ndigite %s" %
				Format(:bold, "/msg #{bot.nick} !autenticar \"<senha>\" \"[<senha_svn>]\""))
		end

		return m.reply Format(:grey, "Ambiente não %s existe." %
			Format(:bold, :blue, target)) if shared[:environments][target.to_sym].nil?

		password = shared[:auth][m.user.nick][:password]
		deploy_env ||= target

		begin
			revision = 0

			if shared[:environments][target.to_sym].checked_out?
				m.reply Format(:grey, "Revertendo alterações no código-fonte.")
				revision = shared[:environments][target.to_sym].revert(m.user.nick, password)
			else
				m.reply Format(:grey, "Criando cópia local do código-fonte.")
				revision = shared[:environments][target.to_sym].checkout(m.user.nick, password, "'HEAD'")
			end
			
			m.reply Format(:grey, "Compilando revisao %s do ambiente %s." %
				[Format(:bold, :blue, revision), Format(:bold, :blue, target)])

			shared[:environments][target.to_sym].build

			if target != deploy_env
				m.reply Format(:grey, "Implantando pacotes do ambiente %s no ambiente %s." %
					Format(:bold, :blue, target), Format(:bold, :blue, deploy_env))
			else
				m.reply Format(:grey, "Implantando pacotes do ambiente %s." %
					Format(:bold, :blue, target))
			end

			if (args.length == 2)
				shared[:environments][target.to_sym].deploy(m.user.nick, password)
			else
				shared[:environments][deploy_env.to_sym].deploy(m.user.nick, password,
					shared[:environments][target.to_sym].config.package)
			end

			if target != deploy_env
				m.reply Format(:grey,
					"Pacotes do ambiente %s implantados com sucesso no ambiente %s." %
					[Format(:bold, :blue, target), Format(:bold, :blue, deploy_env)]), true
			else
				m.reply Format(:grey, "Pacotes do ambiente %s implantados com sucesso." %
					Format(:bold, :blue, target)), true
			end
			
		rescue CodinBot::SVNError => s
			m.reply Format(:grey,
				"%s! falha ao atualizar o código do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)]), true
		rescue CodinBot::BuildError => b
			m.reply Format(:grey,
				"%s! falha ao compilar código do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)]), true
		rescue CodinBot::DeployError => d
			m.reply Format(:grey,
				"%s! falha ao implantar pacotes do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)]), true
		end

		unlock_env target
	end

	def help(m)
		m.reply Format(:grey,
			%Q{O prefixo %s oferece comandos de controle sobre a criação
				e implantação de pacotes a partir da cópia local do código-fonte;
				para utilizá-los, digite %s em qualquer janela. Para obter
				ajuda com relação a um comando específico, digite %s.
				Segue abaixo a lista de comandos suportados:} % [
				Format(:bold, :blue, "!build"),
				Format(:bold, :blue, "!build <comando>"),
				Format(:bold, :blue, "!build ajuda <comando>")])
		
		m.reply " "
		m.reply "    " << Format(:grey,
			"LISTA      Exibe uma lista com os ambientes disponíveis")
		m.reply "    " << Format(:grey,
			"COMPILAR   Compila a última revisão do ambiente solicitado")
		m.reply "    " << Format(:grey,
			"IMPLANTAR  Implanta o pacote gerado pela compilação no servidor")
	end

	def help_command(m, command)
		case command
		when /lista/i
			m.reply Format(:grey, "Sintaxe: %s\n" % [Format(:bold, :blue, "!BUILD LISTA")])
			m.reply Format(:grey,
				%Q{Este comando exibe uma lista com os ambientes disponíveis.})
		when /compilar/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!BUILD COMPILAR <ambiente> \"<senha>\"")])
			m.reply Format(:grey,
				%Q{Este comando compila a última versão do código-fonte disponível no
					repositório. Sempre que este comando é chamado, o código é atualizado
					para a última revisão antes de a compilação se iniciar.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de senha. Assim, antes de
					executá-lo, envie o comando de autenticação em conversa privada para
					%s. Para isso, digite %s\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue,
							"/msg #{bot.nick} !autenticar \"<senha>\" [\"<senha_svn>\"]")])
		when /implantar/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!BUILD IMPLANTAR <ambiente> [em <ambiente>] \"<senha>\"")])
			m.reply Format(:grey,
				%Q{Este compila e implanta o pacote gerado no servidor do ambiente
					selecionado. Antes de iniciar a compilação, a cópia local do código
					é atualizada para a última revisão. Opcionalmente, pode-se gerar um
					pacote de um ambiente e implantá-la em outro ambiente utilizando-se
					do argumento "em".})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de senha. Assim, antes de
					executá-lo, envie o comando de autenticação em conversa privada para
					%s. Para isso, digite %s\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue,
							"/msg #{bot.nick} !autenticar \"<senha>\" [\"<senha_svn>\"]")])
		else
			m.reply Format(:grey, "Comando %s não suportado.\n" %
				[Format(:bold, :blue, command)])
		end
	end
end # class