require 'cinch'
require 'open3'

require 'models/errors'

class CodinBot::CommonCommands
	include Cinch::Plugin
	
	match /ajuda$/, :method => :help
	
	match /log$/i, :method => :send_log
	match /log (.+)$/i, :method => :send_log

	match /tail$/i, :method => :tail
	match /tail (.+)$/i, :method => :tail
	match /tail (.+) ([0-9]+)$/i, :method => :tail_n
	
	def tail(m, *target)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!tail <ambiente> [<num_linhas>]")) \
			if target.nil? or target.length < 1

		tail_n(m, target[0], "10")
	end

	def tail_n(m, target, lines)
		return m.reply Format(:grey,
			%Q{A quantidade de linhas não pode ser maior que 30. Para
			visualizar mais linhas, baixe o log com o comando %s.} %
			Format(:bold, :blue, "!log <ambiente>")) if lines.to_i > 30

		return m.reply Format(:grey,
			%Q{Não há log de operações no ambiente %s.} %
			Format(:bold, :blue, target)) if not config[target.to_sym].log?

		m.reply Format(:grey, "Últimas %s linhas do log do ambiente %s:" %
			[Format(:bold, :blue, lines), Format(:bold, :blue, target)])

		output, proc = 
			Open3.capture2e("tail -n #{lines} #{config[target.to_sym].log_file}")

		m.reply Format(:grey, output)
	end

	def send_log(m, *target)
		return m.reply Format(:grey, "Sintaxe: %s" %
			Format(:bold, "!log <ambiente>")) \
			if target.nil? or target.length < 1

		return m.reply Format(:grey,
			%Q{Não há log de operações no ambiente %s.} %
			Format(:bold, :blue, target[0])) if not config[target[0] .to_sym].log?

		m.reply Format(:grey, "Enviando arquivo de log do ambiente %s." %
			Format(:bold, :blue, target[0]))

		m.user.dcc_send(open(config[target[0].to_sym].log_file))
	end

	def help(m)
		m.reply Format(:grey,
			%Q{Segue abaixo a lista de prefixos suportados pelo %s. Para
				utilizá-los, envie uma mensagem com o formato %s:} % [
				Format(:bold, :blue, bot.nick),
				Format(:bold, :blue, "!<comando>")])
		
		m.reply " "
		m.reply "    " << Format(:grey,
			"AJUDA      Mostra esta mensagem de ajuda")
		m.reply "    " << Format(:grey,
			"SVN        Fornece comandos de controle da cópia do código-fonte")
		m.reply "    " << Format(:grey,
			"BUILD      Fornece comandos de compilação e implantação")
		m.reply "    " << Format(:grey,
			"TAIL       Exibe as últimas linhas do log")
		m.reply "    " << Format(:grey,
			"LOG        Baixa o arquivo de log")
	end
end # class