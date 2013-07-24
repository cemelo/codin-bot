require 'cinch'

require 'models/errors'

class CodinBot::SVNCommands
	include Cinch::Plugin
	
	match /svn ajuda$/i, :method => :help
	match /svn ajuda (.+)$/i, :method => :help_command

	match /svn lista$/i, :method => :list
	
	match /svn remover$/i, :method => :remove
	match /svn remover ([[:graph:]]+)$/i, :method => :remove
	
	match /svn (reverter|reverter [[:graph:]]+)$/i, :method => :revert
	match /svn reverter ([[:graph:]]+) \"(.+)\"$/i, :method => :revert

	match /svn obter$/i, :method => :checkout
	match /svn obter ([[:graph:]]+)$/i, :method => :checkout
	match /svn obter ([[:graph:]]+) \"(.+)\"$/i, :method => :checkout
	match /svn obter ([[:graph:]]+) \"(.+)\" (HEAD|[0-9]+)$/i, :method => :checkout
	#match /svn obter ([[:graph:]]+) (\".+\"|[[:graph:]]+) ([[:graph:]]+)$/i, :method => :checkout

	def list(m)
		m.reply Format(:grey, "Lista de ramos disponíveis:")

		config.each do |k|
			m.reply Format(:grey, "    - " << k[0].to_s)
		end
	end

	def remove(m, *args)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn remover <ramo>")) if args.nil? or args.length < 1

		branch = args[0]

		return m.reply Format(:grey, "Ramo não %s existe." %
			Format(:bold, :blue, branch)) if config[branch.to_sym].nil?

		begin
			branch.strip!
			config[branch.to_sym].remove
			
			m.reply Format(:grey, "Diretório do ramo %s removido." %
				Format(:bold, :blue, branch))
		rescue
			m.reply Format(:grey,
				"%s: diretório do ramo %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		end
	end

	def revert(m, *args)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn reverter <ramo> <senha>")) if args.nil? or
				args.length < 3

		branch = args[0]
		password = args[1]

		return m.reply Format(:grey, "Ramo não %s existe." %
			Format(:bold, :blue, branch)) if config[branch.to_sym].nil?

		m.reply Format(:grey, "Revertendo alterações no ramo %s." %
			Format(:bold, :blue, branch))

		begin
			@revision = config[branch.to_sym].revert(m.user.nick, password)

			m.reply Format(:grey,
				"Cópia local do ramo %s revertida para a revisão %s." %	[
					Format(:bold, :blue, branch),
					Format(:bold, :blue, @revision.to_s)])
		
		rescue CodinBot::SVNAuthorizationError => e
			m.reply Format(:grey,
				"%s: acesso negado ao ramo %s. Verifique seu nome de usuário e senha." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		rescue CodinBot::SVNError => e
			m.reply Format(:grey,
				"%s: cópia local do ramo %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		end
	end

	def checkout(m, *args)
		if args.length < 2 or args.length > 3
			return m.reply Format(:grey, "Sintaxe: %s" %
				Format(:bold, "!svn obter <ramo> <senha> [<revisão>]"))
		end

		branch = args[0]
		password = args[1]
		revision = args[2]

		return m.reply Format(:grey, "Ramo não %s existe." %
			Format(:bold, :blue, branch)) if config[branch.to_sym].nil?
		
		if config[branch.to_sym].checked_out?
			m.reply Format(:grey, "Atualizando cópia local do ramo %s." %
				Format(:bold, :blue, branch))
		else
			m.reply Format(:grey, "Criando cópia local do ramo %s. Aguarde..." %
				Format(:bold, :blue, branch))
		end

		begin
			@revision = config[branch.to_sym].checkout(m.user.nick, password,
				revision)

			m.reply Format(:grey,
				"Criada cópia local da revisão %s do ramo %s." %	[
					Format(:bold, :blue, @revision.to_s),
					Format(:bold, :blue, branch)])
		rescue CodinBot::SVNAuthorizationError => e
			m.reply Format(:grey,
				"%s: acesso negado ao ramo %s. Verifique seu nome de usuário e senha." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		rescue CodinBot::SVNError => e
			m.reply Format(:grey,
				"%s: não foi possível criar cópia local do ramo %s." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		end
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
			"LISTA     Exibe uma lista com os ramos disponíveis")
		m.reply "    " << Format(:grey,
			"OBTER     Obtém a última revisão de um ramo específico")
		m.reply "    " << Format(:grey,
			"REVERTER  Reverte quaisquer alterações feitas no diretório de trabalho")
		m.reply "    " << Format(:grey,
			"REMOVER   Remove o diretório de trabalho de um ramo específico")
	end

	def help_command(m, command)
		case command
		when /lista/i
			m.reply Format(:grey, "Sintaxe: %s\n" % [Format(:bold, :blue, "!SVN LISTA")])
			m.reply Format(:grey,
				%Q{Este comando exibe uma lista com os ramos disponíveis.})
		when /obter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN OBTER <ramo> <senha> [<revisao>]")])
			m.reply Format(:grey,
				%Q{Este comando cria ou atualiza a cópia local do código-fonte no
					servidor. Deve ser chamado sempre que um ramo novo for criado no
					SVN, ou quando houver a remoção da cópia local de um ramo, ou quando
					se desejar utilizar uma revisão específica.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de autenticação.
					Assim, para executá-lo, utilize uma conversa privada com %s.
					Para isso, digite %s.\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue, "/msg #{bot.nick} !svn <comando>")])
		when /reverter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN REVERTER <ramo> <senha>")])
			m.reply Format(:grey,
				%Q{Este comando reverte alterações na cópia local do código-fonte no
					servidor. Não tem muito uso prático pois sempre é chamado antes de
					uma compilação de código.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de autenticação.
					Assim, para executá-lo, utilize uma conversa privada com %s.
					Para isso, digite %s.\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue, "/msg #{bot.nick} !svn <comando>")])
		when /remover/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!SVN REMOVER <ramo>")])
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