#
# Author:: Renan Strauss
#
# The Checker is a component that wraps
# all required tools to do the analysis.
# It adapts itself dynamically
# to the language Cfg.
#
#
require 'open3'

require_relative 'code_analysis_tools'
require_relative 'compilation_tools'
require_relative 'execution_tools'

class Checker < Component
	include CodeAnalysisTools

	def initialize(data)
		super data

		@results = {}

		if Cfg[:compiled]
			extend CompilationTools
		end

		extend ExecutionTools unless (!Cfg[:compiled] && !Cfg.has_key?(:execute_command))
	end

	# Yann : je ne recupere pas les datas de l'organiser,
	# Je considere que tous les projets sont dans le dossier courant.
	# TODO a voir si cela marche dans certains cas particuliers
	def run
		# We'll work in the dest directory
		Dir.chdir Cfg[:dest] do
			projects = Dir.entries('.') - ['.','..']
			projects.each_with_index do |proj, i| 
				puts "\t[#{i+1}/#{projects.size}]\t#{proj}"
				Dir.chdir(proj) { check proj }
			end
		end

		@results
	end

private

	#
	# Being called in the project's directory,
	# this methods maps all the criterias to
	# their analysis value
	#
	def check(proj)
		#
		# First we iterate over criterias
		# defined in config
		#
		@results[proj] = {}
		Cfg[:criterias].each do |meth, crit|
			begin
				@results[proj][crit] = send meth
			rescue NoMethodError
				@logger.fatal { "You specified an undefined method in config : #{meth}" }
			end
		end

		#
		# Then we look for external modules
		#
		Cfg[:extensions].each do |ext, crits|
			begin
				@logger.debug { "Including extension #{ext}, located in #{File.join(Cfg::ROOT, 'ext', "#{ext}.rb")}, whose class name is #{camelize(ext)}" }
				require File.join(Cfg::ROOT, 'ext', "#{ext}.rb")
				extend Object.const_get "#{camelize ext}"
			rescue Object => e
				@logger.fatal { "Unable to load extension #{ext}, here's why : #{e.to_s}" }
			end

			crits.each do |meth, crit|
				begin
					@logger.debug { "Calling #{meth} for #{crit}" }
					@results[proj][crit] = send meth
					@logger.debug { "Result is : #{@results[proj][crit]}" }
				rescue NoMethodError
					@logger.fatal { "You specified an undefined method in config : #{meth}" }
				end
			end
		end
	end

	#
	# For interpreted languages
	# We only check for missing files
	#
	def prepare
		missing_files.empty? && 'None' || res
	end

	#
	# This method checks for required files
	# Typically needed for C with Makefile
	# 
	def missing_files
		return [] unless Cfg =~ :required_files

		dir = Dir['*']

		#
		# Check if there is any regexp
		# If it's the case, if any file
		# matches, we delete the entry
		# for diff to work properly
		#
		Cfg[:required_files].each_with_index do |e, i|
			if dir.any? { |f| (e.respond_to?(:match)) && (e =~ f) }
				Cfg[:required_files].delete_at i
			end
		end

		Cfg[:required_files] - dir
	end

	#
	# Executes the given command
	# and kills it if its execution
	# time > timeout
	# @returns stdout, stderr & process_status
	#
	def exec_with_timeout(cmd, timeout = Cfg[:timeout])
		stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
		process_status = -1

		stdin.close
		#
		# We try to wait for the thread to join
		# during the given timeout.
		# When the thread has joined, process_status
		# will be an object, so we can check and
		# return at the end if it failed to complete
		# before time runs out.
		#
		begin
			Timeout.timeout(timeout) do
				process_status = wait_thr.value
			end
		rescue Timeout::Error
			#
			# Then whether it suceeded or not,
			# we kill the process
			#
			begin
				Process.kill('KILL', wait_thr[:pid])
			rescue Object => e
				$stderr << "Unable to kill process : #{e.to_s}"
			end
		end

		result = {
			:stdout => process_status == -1 && 'Timeout' || stdout.read,
			:stderr => process_status == -1 && 'Timeout' || stderr.read,
			:process_status => process_status == -1 && 'Timeout' || process_status
		}
		
		result.delete :process_status unless process_status != -1

		stdout.close
		stderr.close

		result
	end

	#
	# Gets the name of module 
	# @param file_module Name of the file module.
	#
	def camelize(basename) 
		basename.split('_').each {|s| s.capitalize! }.join('')
	end
end