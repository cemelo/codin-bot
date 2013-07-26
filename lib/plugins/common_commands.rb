require 'cinch'
require 'open3'

require 'models/errors'

class CodinBot::CommonCommands
	include Cinch::Plugin
	
	match /ajuda$/i, :method => :help
	
	match /autenticar(?:[ ]\"(.*)\")?(?:[ ]\"(.*)\")?$/ix, :method => :auth
	
	match /desautenticar$/i, :method => :deauth

	match /lista$/i, :method => :list

	match /log(?:[ ]([[:graph:]]+))?$/ix, :method => :send_log

	match /tail(?:[ ]([[:graph:]]+))?
		(?:[ ](\d+))?
		(?:(?<![ ])$)/ix, :method => :tail
	
	def auth(m, password, svn_password)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!autenticar <senha> [<senha_svn>]")) \
			if password.nil?

		svn_password ||= password

		shared[:auth][m.user.nick] = {
			:password => password,
			:svn_password => svn_password
		}

		m.reply Format(:grey, "Senha do usuário %s salva." %
			Format(:bold, :blue, m.user.nick))
	end

	def deauth(m)
		shared[:auth].delete(m.user.nick)

		m.reply Format(:grey, "Senha do usuário %s removida." %
			Format(:bold, :blue, m.user.nick))
	end

	def list(m)
		m.reply Format(:grey, "Lista de ambientes disponíveis:")

		shared[:environments].each_pair do |k, v|
			m.reply "    " << Format(:grey, "- #{v.config.description} (#{k})")
		end
	end

	def tail(m, target, num_lines)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!tail <ambiente> [<num_linhas>]")) \
			if target.nil?

		num_lines = "30" if num_lines.to_i > 30
		num_lines ||= "10"
		tail_n(m, target, num_lines)
	end

	def tail_n(m, target, lines)
		return m.reply Format(:grey,
			%Q{A quantidade de linhas não pode ser maior que 30. Para
			visualizar mais linhas, baixe o log com o comando %s.} %
			Format(:bold, :blue, "!log <ambiente>")) if lines.to_i > 30

		return m.reply Format(:grey,
			%Q{Não há log de operações no ambiente %s.} %
			Format(:bold, :blue, target)) if not shared[:environments][target.to_sym].log?

		m.reply Format(:grey, "Últimas %s linhas do log do ambiente %s:" %
			[Format(:bold, :blue, lines), Format(:bold, :blue, target)])

		output, proc = 
			Open3.capture2e("tail -n #{lines} #{shared[:environments][target.to_sym].log_file}")

		m.reply Format(:grey, output)
	end

	def send_log(m, target)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!log <ambiente>")) if target.nil?

		return m.reply Format(:grey,
			%Q{Não há log de operações no ambiente %s.} %	Format(:bold, :blue, target)) \
				unless shared[:environments][target.to_sym].log?

		m.reply Format(:grey, "Enviando arquivo de log do ambiente %s." %
			Format(:bold, :blue, target))

		m.user.dcc_send(open(shared[:environments][target.to_sym].log_file))
	end

	def help(m)
		m.reply Format(:grey,
			%Q{Segue abaixo a lista de prefixos suportados pelo %s. Para
				utilizá-los, envie uma mensagem com o formato %s:} % [
				Format(:bold, :blue, bot.nick),
				Format(:bold, :blue, "!<comando>")])
		
		m.reply " "
		m.reply "    " << Format(:grey,
			"AJUDA          Mostra esta mensagem de ajuda")
		m.reply "    " << Format(:grey,
			"AUTENTICAR     Autentica o usuário para operações com senha")
		m.reply "    " << Format(:grey,
			"DESAUTENTICAR  Remove a sessão do usuário")
		m.reply "    " << Format(:grey,
			"LISTA          Exibe uma lista com os ambientes disponíveis")
		m.reply "    " << Format(:grey,
			"SVN            Fornece comandos de controle da cópia do código-fonte")
		m.reply "    " << Format(:grey,
			"BUILD          Fornece comandos de compilação e implantação")
		m.reply "    " << Format(:grey,
			"TAIL           Exibe as últimas linhas do log")
		m.reply "    " << Format(:grey,
			"LOG            Baixa o arquivo de log")
	end
end # class