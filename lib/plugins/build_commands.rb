require 'cinch'
require_relative '../build'

class CodinBot::BuildCommands
	include Cinch::Plugin
	include CodinBot::Build
	
	match /build ajuda$/i, :method => :help
	match /build ajuda (.+)$/i, :method => :help_command

	match /build compilar$/i, :method => :compile
	match /build compilar ([[:graph:]]+)$/i, :method => :compile
	match /build compilar ([[:graph:]]+) \"(.+)\"$/i, :method => :compile

	match /build implantar$/i, :method => :deploy

	def build(m, target, password)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!svn compilar <ambiente>")) if not match

		begin
			target.strip!
			Remove(config[target.to_sym][:dir])
			
			m.reply Format(:grey, "Diretório do ramo %s removido." %
				Format(:bold, :blue, target))
		rescue
			m.reply Format(:grey,
				"%s: diretório do ramo %s não existe." %
				[Format(:bold, :red, "ERRO"), Format(:bold, :blue, target)])
		end
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
		when /obter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!BUILD COMPILAR <ambiente> <senha>")])
			m.reply Format(:grey,
				%Q{Este comando compila a última versão do código-fonte disponível no
					repositório. Sempre que este comando é chamado, o código é atualizado
					para a última revisão antes de a compilação se iniciar.})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de autenticação.
					Assim, para executá-lo, utilize uma conversa privada com %s.
					Para isso, digite %s.\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue, "/msg #{bot.nick} !build <comando>")])
		when /reverter/i
			m.reply Format(:grey, "Sintaxe: %s\n" %
				[Format(:bold, :blue, "!BUILD IMPLANTAR <ambiente> [em <ambiente>] \"<senha>\"")])
			m.reply Format(:grey,
				%Q{Este compila e implanta o pacote gerado no servidor do ambiente
					selecionado. Antes de iniciar a compilação, a cópia local do código
					é atualizada para a última revisão. Opcionalmente, pode-se gerar um
					pacote de um ambiente e implantá-la em outro ambiente utilizando-se
					do argumento "em".})
			m.reply Format(:grey,
				%Q{%s! Este comando necessita de informações de autenticação.
					Assim, para executá-lo, utilize uma conversa privada com %s.
					Para isso, digite %s.\n} % [
					Format(:bold, "Atenção"),
					Format(:bold, :blue, bot.nick),
					Format(:bold, :blue, "/msg #{bot.nick} !svn <comando>")])
		m.reply Format(:grey, "Comando %s não suportado.\n" %
				[Format(:bold, :blue, command)])
		end
	end
end # class