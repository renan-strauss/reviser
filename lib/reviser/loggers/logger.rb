require 'logger'
require_relative 'modes'

module Reviser
	module Loggers

		class Logger::LogDevice
			def add_log_header(file)
			end
		end

		# Custom logger of Reviser.
		# This class is a adapter.
		# We used the standard Logger included in Ruby.
		#
		# @author Yann Prono
		#
		class Logger

			# Creates logger.
			# The extension determines the mode to use (logger mode).
			# @param filename [String] name of logger.
			def initialize filename
				ext = File.extname filename
				@basename = File.basename filename, ext
				ext = ext.delete '.'
				# Include mode aksed by user (config file)
				begin
					self.class.send :prepend, Modes.const_get("#{ext.downcase.capitalize}")
				rescue => e
					self.class.send :include, Modes::Txt
				end

				@logger = ::Logger.new File.open(filename, 'w')
				@logger.level = ::Logger::DEBUG
		  	end

		  	# Closes the logger
		  	def close
		  		@logger.close
		  	end

		  	# In case of someone want to use methods of standard Logger ...
		  	def method_missing(m, *args, &block)
					@logger.send m, *args, &block
		  	end
		end
	end
end