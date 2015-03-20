require 'logger'

#
# Modules containing all methods to custom logger.
# 
# There are 3 main level of logger (as in HTML)
# => h1
# => h2
# => h3

# @author Yann Prono
# @author Anthony Cerf
# @author Romain Ruez

module Loggers
	module Modes

		module Txt

			include Modes

			def h1 severity, msg
				change_formatter ''
				@logger.add severity, msg
			end

			def h2 severity, msg
				change_formatter "\t\t"
				@logger.add severity, msg
			end

			def h3 severity, msg
				change_formatter "\t\t\t"
				@logger.add severity, msg
			end
		end

		module Org

			include Modes
			
			def h1 severity, msg
				change_formatter '*'
				@logger.add severity, msg
			end

			def h2 severity, msg
				change_formatter "**"
				@logger.add severity, msg
			end

			def h3 severity, msg
				change_formatter "***"
				@logger.add severity, msg
			end

		end
		
		module Html
			include Modes

			@@add_header = false
			def header
				add_tag "<!DOCTYPE html><html><head>
				<meta charset= \"UTF-8\">
				<link rel=\"stylesheet\" href=\"#{Cfg[:res_dir]}/css/component.css\" />
				<link rel=\"stylesheet\" href=\"#{Cfg[:res_dir]}/css/normalize.css\" />
				<script src=\"res/js/component.css\"></script>
				<title>Results</title>
				</head>\n<body>"
				@@add_header = true
			end

			def h1 severity,msg
				header unless @@add_header
				change_formatter '<h1>' , '</h1>'
				@logger.add severity , msg
			end
			
			def h2 severity,msg
				header unless @@add_header
				change_formatter '<h2>' , '</h2>'
				@logger.add severity , msg
			end
			
			def h3 severity,msg
				header unless @@add_header
				change_formatter '<h3>' , '</h3>'
				@logger.add severity , msg
			end

			def close
				add_tag '</body></html>'
				@logger.close
			end
			
		end
		
		
		# Change formatter
		# @param prefix Prefix to put before all content
		def change_formatter prefix , suffix = ''
			@logger.formatter = proc do |severity, datetime, progname, msg|
				"\n#{prefix} #{severity} #{msg} #{suffix}"
			end
		end

		# Create new line
		def newline
			@logger.formatter = proc do |severity, datetime, progname, msg|
				"\n#{msg}"
			end
			@logger.add(nil,"\n")
		end

		def add_tag tag
			@logger.formatter = proc do |severity, datetime, progname, msg|
				"\n#{msg}"
			end
			@logger.add(nil,tag)
		end

	end
end