require 'cinch'

require 'models/errors'

class CodinBot::SVNCommands
	include Cinch::Plugin
	
	match /svn ajuda$/i, :method => :help
	match /svn ajuda(?:[ ]([[:graph:]]+))$/ix, :method => :help_command

	match /svn[ ]remover[ ]?
		((?<=[ ])[[:graph:]]+)?
		(?<![ ])$/ix, :method => :remove

	match /svn[ ]reverter[ ]?
		((?<=[ ])[[:graph:]]+)?
		(?<![ ])$/ix, :method => :revert

	match /svn[ ]obter[ ]?
		((?<=obter[ ])[[:graph:]]+)?[ ]?
		((?<!obter[ ])(?<=[ ])[0-9]+)?$/ix, :method => :checkout

	match /svn[ ]monitor[ ]?
		((?<=monitor[ ])[[:graph:]]+)?[ ]?
		((?<!monitor[ ])(?<=[ ])[[:graph:]]+)?
		(?<![ ])$/ix, :method => :monitor

	def lock_env(user, branch)
		return shared[:environments][branch.to_sym].lock user
	end

	def unlock_env(branch)
		shared[:environments][branch.to_sym].unlock
	end

	def remove(m, branch)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn remover <ambiente>")) if branch.nil?

		return m.reply Format(:grey, "Ambiente não %s existe." %
			Format(:bold, :blue, branch)) if shared[:environments][branch.to_sym].nil?

		begin
			return m.reply Format(:grey, "%s! Ambiente em uso por %s." % [
				Format(:bold, :red, "ERRO"),
				Format(:bold, :blue, shared[:environments][branch.to_sym].locking_user)
			]) unless lock_env m.user.nick, branch

			shared[:environments][branch.to_sym].remove
			
			m.reply Format(:grey, "Cópia local do ambiente %s removida." %
				Format(:bold, :blue, branch)), true
		rescue
			m.reply Format(:grey,
				"%s! cópia local do ambiente %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		end

		unlock_env branch
	end

	def revert(m, branch)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn reverter <ambiente>")) if branch.nil?

		unless shared[:auth][m.user.nick]
			return m.reply Format(:grey,
				"Este comando exige autenticação. Para autenticar-se,\ndigite %s" %
				Format(:bold, "/msg #{bot.nick} !autenticar \"<senha>\" \"[<senha_svn>]\""))
		end

		password = shared[:auth][m.user.nick][:svn_password]

		return m.reply Format(:grey, "Ambiente não %s existe." %
			Format(:bold, :blue, branch)) if shared[:environments][branch.to_sym].nil?

		begin
			return m.reply Format(:grey, "%s! Ambiente em uso por %s." % [
				Format(:bold, :red, "ERRO"),
				Format(:bold, :blue, shared[:environments][branch.to_sym].locking_user)
			]) unless lock_env m.user.nick, branch

			m.reply Format(:grey, "Revertendo alterações no ambiente %s." %
				Format(:bold, :blue, branch))

			@revision = shared[:environments][branch.to_sym].revert(m.user.nick, password)

			m.reply Format(:grey,
				"Cópia local do ambiente %s revertida para a revisão %s." %	[
					Format(:bold, :blue, branch),
					Format(:bold, :blue, @revision.to_s)]), true
		
		rescue CodinBot::SVNAuthorizationError => e
			m.reply Format(:grey,
				"%s! Acesso negado ao ambiente %s. Verifique seu nome de usuário e senha." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue,
					shared[:environments][branch.to_sym].config.svn_branch)]), true
		rescue CodinBot::SVNError => e
			m.reply Format(:grey,
				"%s! Cópia local do ambiente %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		rescue
			m.reply Format(:grey,
				"%s! Falha desconhecida." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		end

		unlock_env branch
	end

	def checkout(m, branch, revision)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn obter <ambiente> [<revisão>]")) if branch.nil?

		unless shared[:auth][m.user.nick]
			return m.reply Format(:grey,
				"Este comando exige autenticação. Para autenticar-se,\ndigite %s" %
				Format(:bold, "/msg #{bot.nick} !autenticar \"<senha>\" \"[<senha_svn>]\""))
		end

		password = shared[:auth][m.user.nick][:svn_password]

		return m.reply Format(:grey, "Ambiente %s não existe." %
			Format(:bold, :blue, branch)) if shared[:environments][branch.to_sym].nil?

		begin
			return m.reply Format(:grey, "%s! Ambiente em uso por %s." % [
				Format(:bold, :red, "ERRO"),
				Format(:bold, :blue, shared[:environments][branch.to_sym].locking_user)
			]) unless lock_env m.user.nick, branch

			if shared[:environments][branch.to_sym].checked_out?
				m.reply Format(:grey, "Atualizando cópia local do ambiente %s." %
					Format(:bold, :blue, branch))
			else
				m.reply Format(:grey, "Criando cópia local do ambiente %s. Aguarde..." %
					Format(:bold, :blue, branch))
			end

			@revision = shared[:environments][branch.to_sym].checkout(m.user.nick, password,
				revision)

			m.reply Format(:grey,
				"Criada cópia local da revisão %s do ramo %s." %	[
					Format(:bold, :blue, @revision.to_s),
					Format(:bold, :blue, branch)]), true
		rescue CodinBot::SVNAuthorizationError => e
			m.reply Format(:grey,
				"%s! Acesso negado ao ambiente %s. Verifique seu nome de usuário e senha." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		rescue CodinBot::SVNError => e
			m.reply Format(:grey,
				"%s! Não foi possível criar cópia local do ambiente %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		rescue
			m.reply Format(:grey,
				"%s! Falha desconhecida." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)]), true
		end

		unlock_env branch
	end

	def monitor(m, action, branch)
		return m.reply Format(:grey, "Sintaxe: %s" %
				Format(:bold, "!svn monitor <iniciar|parar> <ambiente>")) \
			if action.nil? or branch.nil? or not /iniciar|parar/i.match action

		unless shared[:auth][m.user.nick]
			return m.reply Format(:grey,
				"Este comando exige autenticação. Para autenticar-se,\ndigite %s" %
				Format(:bold, "/msg #{bot.nick} !autenticar \"<senha>\" \"[<senha_svn>]\""))
		end

		password = shared[:auth][m.user.nick][:svn_password]

		if shared[:environments][branch.to_sym].monitoring_thread
			return m.reply Format(:grey,
				"%s! O ambiente %s já está sendo monitorado." %
					[Format(:bold, :red, "ERRO"), Format(:bold, :red, branch)]
				) if /^iniciar$/i.match action
		else
			return m.reply Format(:grey,
				"%s! O ambiente %s não está sendo monitorado." %
					[Format(:bold, :red, "ERRO"), Format(:bold, :red, branch)]
				) if /^parar$/i.match action
		end

		if /^parar$/i.match action
			shared[:environments][branch.to_sym].monitoring_thread.terminate

			return m.reply Format(:grey, "Monitor do ramo %s encerrado." % Format(:bold, :blue,
					shared[:environments][branch.to_sym].config.svn_branch))
		end

		shared[:environments][branch.to_sym].monitoring_thread = Thread.new do
				last_revision = 0
				
				m.reply Format(:grey, "Monitorando ramo %s." % Format(:bold, :blue,
					shared[:environments][branch.to_sym].config.svn_branch))

				loop do
					revision, author, datetime, message =
						shared[:environments][branch.to_sym].last_log(m.user.nick, password)

					if last_revision == revision
						sleep config[:monitor_sleep_interval] || 5
						redo
					end

					message.strip!
					message = "<sem mensagem>" if message.empty?

					base_msg = ("-" * 72) <<
						%Q{\nCommit da revisão %s por %s no ramo %s.\nEm: %s\n} <<
						("-" * 72) << %Q{\nMensagem:\n#{message}\n} << ("-" * 72)

					redmines = message.scan(/\#(\d+)/).flatten.uniq.sort

					base_msg << "\nRedmines:" unless redmines.empty?
					redmines.each do |r|
						base_msg << "\n\##{r}: "
						base_msg << Format(:grey, "https://dia-a-dia-sof/redmine/issues/#{r}")
					end
					base_msg << "\n" << ("-" * 72) unless redmines.empty?

					chann_msg = Format(:grey, base_msg % [
								Format(:bold, revision.to_s),
								Format(:bold, :blue, author),
								Format(:bold, :blue, shared[:environments][branch.to_sym].config.svn_branch),
								Format(:bold, datetime.strftime("%H:%M:%S %d/%m/%Y"))])

					bot.channels.each do |channel|
						channel.msg chann_msg, true
					end

					last_revision = revision
				end # loop
			end # Thread
	end

	def help(m)
		m.reply Format(:grey,
			%Q{O prefixo %s oferece comandos de controle sobre a cópia
				do código-fonte no servidor; para utilizá-los, digite
				%s em qualquer janela. Para obter	ajuda com relação a um
				comando específico, digite %s.} % [
				Format(:bold, :blue, "!svn"),
				Format(:bold, :blue, "!svn <comando>"),
				Format(:bold, :blue, "!svn ajuda <comando>")])
		
		m.reply " "
		m.reply "    " << Format(:grey,
			"OBTER     Obtém a última revisão de um ramo específico")
		m.reply "    " << Format(:grey,
			"MONITOR   Cria ou encerra um monitor de commits em um ramo")
		m.reply "    " << Format(:grey,
			"REVERTER  Reverte quaisquer alterações feitas no diretório de trabalho")
		m.reply "    " << Format(:grey,
			"REMOVER   Remove o diretório de trabalho de um ramo específico")
	end

	def help_command(m, command)
		case command
		when /obter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN OBTER <ambiente> [<revisao>]")])
			m.reply Format(:grey,
				%Q{Este comando cria ou atualiza a cópia local do código-fonte no
					servidor. Deve ser chamado sempre que um ramo novo for criado no
					SVN, ou quando houver a remoção da cópia local de um ramo, ou quando
					se desejar utilizar uma revisão específica.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de senha. Assim, antes de
					executá-lo, envie o comando de autenticação em conversa privada para
					%s. Para isso, digite %s\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue,
							"/msg #{bot.nick} !autenticar \"<senha>\" [\"<senha_svn>\"]")])
		when /monitor/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN MONITOR <iniciar|parar> <ambiente>")])
			m.reply Format(:grey,
				%Q{Este comando cria ou para um monitor de commits em um ramo.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de senha. Assim, antes de
					executá-lo, envie o comando de autenticação em conversa privada para
					%s. Para isso, digite %s\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue,
							"/msg #{bot.nick} !autenticar \"<senha>\" [\"<senha_svn>\"]")])
		when /reverter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN REVERTER <ambiente>")])
			m.reply Format(:grey,
				%Q{Este comando reverte alterações na cópia local do código-fonte no
					servidor. Não tem muito uso prático pois sempre é chamado antes de
					uma compilação de código.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de senha. Assim, antes de
					executá-lo, envie o comando de autenticação em conversa privada para
					%s. Para isso, digite %s\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue,
							"/msg #{bot.nick} !autenticar \"<senha>\" [\"<senha_svn>\"]")])
		when /remover/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN REMOVER <ambiente>")])
			m.reply Format(:grey,
				%Q{Este comando remove a cópia local do código-fonte no servidor. Deve
					ser utilizado sempre que houver algum problema com a cópia local que não
					possa ser solucionada através do comando %s.\n} % 
						[Format(:bold, :blue, "REVERTER")])
		else
			m.reply Format(:grey, "Comando %s não suportado.\n" %
				[Format(:bold, :blue, command)])
		end
	end
end # class