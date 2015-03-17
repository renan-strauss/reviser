require 'rubygems'
require 'fileutils'

# The module contains all methods to uncompress a archive 
# regardless the format.

# Convention over configuration !
#
# To add a new format, maybe you need to install the Gem.
# Find a Gem which uncompress a specified format on rubygems.org.
# Add the line "gem <gem>" in the Gemfile and execute "bundle install"
#
# Now, you can write the method corresponding to the format.
# The name of the method corresponds to the format.
# For example, if you want to use rar format, the name of the method will be: "rar"
# Don't forget to require the gem: "require <gem>" at the beginning of the method !
# the header of method looks like the following block:
#
#  		def <format> (src, destination)
# 			require <gem>
# 			...
# 		end
#
# @author 	Anthony Cerf
# @author 	Yann Prono
#
module Components
	module Extractors	
		#
		# Method which unzip a file.
		# ZIP format
		#
		def zip (src, destination)
			require 'zip'
			# Cfg the gem
			Zip.on_exists_proc = true
			Zip.continue_on_exists_proc = true

			Zip::File.open(src) do |zip_file|
				#Entry = file or directory
		  		zip_file.each do |entry|
	  				#Create filepath
	 				filepath = File.join(destination, entry.name)
		  			# Check if it doesn't exist because of directories (overwrite)
					unless File.exist?(filepath)
						# Create directories to access file
						FileUtils.mkdir_p(File.dirname(filepath))
						entry.extract(filepath)
					end
	  			end
			end
		end
		
		#
		# Method which ungzip a file
		# gzip format
		#
		def gz (tarfile,destination)
			require 'zlib'
	      	z = Zlib::GzipReader.open(tarfile)
	      	unzipped = StringIO.new(z.read)
	      	z.close
	      	tar(unzipped, destination)
		end

		# Alias for format shortcut
		## cc Dominique Colnet
		alias :tgz :gz 
	    
	    #
		# Method which untar a file
		# tar format
		#
		def tar (src,destination)
			require 'rubygems/package'
	    	# test if src is String (filename) or IO stream
	    	if src.is_a? String
	    		stream = File.open(src)
	    	else
	    		stream = src
	    	end

	    	Gem::Package::TarReader.new(stream) do |tar|
		        tar.each do |tarfile|
		          	destination_file = File.join destination, tarfile.full_name
		          	if tarfile.directory?
		            	FileUtils.mkdir_p destination_file
					else
			            destination_directory = File.dirname(destination_file)
			            FileUtils.mkdir_p destination_directory unless File.directory?(destination_directory)
			            File.open destination_file, 'wb' do |f|
			              	f.print tarfile.read
			          	end
		     		end
		  		end
	  		end
		end

	 	#
	 	# Uncompress rar format
	 	# if it is possible.
	 	#
		def rar(src,destination)
			require 'shellwords'
	 		`which unrar`
	 		if $?.success?
	 			src = Shellwords.escape(src)
	 			destination = Shellwords.escape(destination)
	 			`unrar e #{src} #{destination}`
			else
				puts 'Please install unrar : sudo apt-get install unrar'
			end
		end

		#
		# Uncompress a 7zip file
		#
		def seven_zip(src, destination)
			require 'seven_zip_ruby'
			File.open(src, 'rb') do |file|
	  			SevenZipRuby::Reader.open(file) do |szr|
	    			szr.extract_all destination
	  			end
			end
		end

		#
		# Tip for call 7zip method 
		#
		def method_missing(m, *args, &block)  
	    	if (ext = File.extname(args[0]).delete('.') == '7z')
	    		seven_zip(args[0], args[1])
	    	else 
	    		raise "Format '#{ext.delete('.')}' not supported"
	    	end
	  	end
	end
end