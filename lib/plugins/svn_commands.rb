require 'cinch'
require_relative '../svn'

class CodinBot::SVNCommands
	include Cinch::Plugin
	include CodinBot::SVN
	
	match /svn ajuda$/i, :method => :help
	match /svn ajuda (.+)$/i, :method => :help_command

	match /svn lista$/i, :method => :list
	match /svn remover(\s(.+))$/i, :method => :remove
	match /svn reverter(\s(.+) (.+))?$/i, :method => :revert
	match /svn obter((\s[a-z]+)$|(\s[a-z]+){2}$|\s(.+)\s(.+)\s(.+)$)?/i, :method => :checkout

	def list(m)
		m.reply Format(:grey, "Lista de ramos disponíveis:")

		config.each do |k|
			m.reply Format(:grey, "    - " << k)
		end
	end

	def remove(m, match, branch)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn remover <ramo>")) if not match

		begin
			branch.strip!
			Remove(config[branch.to_sym][:dir])
			
			m.reply Format(:grey, "Diretório do ramo %s removido." %
				Format(:bold, :blue, branch))
		rescue
			m.reply Format(:grey,
				"%s: diretório do ramo %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		end
	end

	def revert(m, match, branch, password)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn reverter <ramo> <senha>")) if not match

		m.reply Format(:grey, "Revertendo alterações no ramo %s." %
			Format(:bold, :blue, branch))

		begin
			@revision = Revert(config[branch.to_sym][:url],
				config[branch.to_sym][:dir],
				m.user.nick, password)

			m.reply Format(:grey,
				"Cópia local do ramo %s revertida para a revisão %s." %	[
					Format(:bold, :blue, branch),
					Format(:bold, :blue, @revision.to_s)])
		rescue
			m.reply Format(:grey,
				"%s: cópia local do ramo %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, branch)])
		end
	end

	def checkout(m, *args, branch, password, revision)
		puts args.inspect
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn obter <ramo> <senha>")) if password.nil?

		return
		
		if File.directory? config[branch.to_sym][:dir]
			m.reply Format(:grey, "Atualizando cópia local do ramo %s." %
				Format(:bold, :blue, branch))
		else
			m.reply Format(:grey, "Criando cópia local do ramo %s. Aguarde..." %
				Format(:bold, :blue, branch))
		end

		begin
			@revision = Checkout(config[branch.to_sym][:url],
					config[branch.to_sym][:dir],
					m.user.nick, password, revision)

			m.reply Format(:grey,
				"Criada cópia local da revisão %s do ramo %s." %	[
					Format(:bold, :blue, @revision.to_s),
					Format(:bold, :blue, branch)])
		rescue
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
		end
	end
end # class