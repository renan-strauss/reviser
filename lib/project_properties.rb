#
# This modules is used to get all students who worked 
# in the project, thanks to convention given by teachers (config file).

# @author Yann Prono
module ProjectProperties

	# Dictionnary for regex in config file
	SYMBOLS = {
		:class 	=> 'CLASS',
		:firstname 	=> 'FIRSTN',
		:name 	=> 'NAME',
		:user 	=> 'USER',
		:lambda	=>	'LAMBDA'
	}

	# Regex to associate, depending the used word in Cfg
	REGEX = {
		:class 	=> '([^_]*)',
		:firstname 	=> '([A-Za-z\-]+)',
		:name 	=> '([A-Za-z]+)', 
		:user 	=> '([^_]*)',
		:lambda 	=> '[a-zA-Z0-9 _]*',
	}

	# Get formatter written in the config file
	# And count occurences of  each word in the dictionnary SYMBOLS
	# @return Hash sym => count
	def analyze_formatter
		regex = Cfg[:projects_names]
		# Foreach known symbol
		SYMBOLS.each do |k,v|
			# Get numbers of occurences of the word k in regex 
			matches = regex.scan(SYMBOLS[k]).size
			# the word K => number of occurences
			@count[k] = matches if matches > 0
		end
	end

	# Analyze et get all informations 
	# that could be useful in the name of the
	# directory project.
	# @param entry Project to read
	def format entry
		ext = File.extname entry
		entry = File.basename entry, ext

		analyze_formatter if @count.empty?

		regex = Cfg[:projects_names]

		nb_students = 0

		group = check_entry_name entry
		generate_label group
	end

	# Generate new name of project
	# @param infos All informations used for 
	# generate a name for the directory.
	# @return String the formatted label
	def generate_label infos
		if !infos.empty?
			label = ""
			infos.each {|i| label += label == "" ? i : " " + i }
			label
		end
	end

	# I'm not pround of this method ...
	def get_position regex
		res = {}
		SYMBOLS.each do |k,v|
			regex.scan(v) do |c|
				res[$~.offset(0)[0]] = k
			end
		end

		res = (res.sort_by { |k,v| k }).to_h
		tmp = {}

		index = 1
		res.each do |k,v|
			tmp[index] = v
			index += 1
		end
		tmp
	end

	
	def check_entry_name entry
		regex = Cfg[:projects_names]
		group = []
		position = get_position regex

		@count.each do |k,v|
			regex = regex.gsub SYMBOLS[k], REGEX[k]
		end
		
		# Apply created regex
		entry.match Regexp.new(regex)
		pos = 1

		begin
			tmp = eval "$#{pos}"
			if tmp != nil
				group << tmp
			end
			pos += 1
		end while pos <= position.size

		@groups << group
		analyze_group group
		group
	end

	def analyze_group grp
		formalized = []
		if @count.key? :firstname
			require 'enumerator'
			grp.each_slice(2) do |k,v|
				student = "#{k} #{v}"
				formalized << student
				@students << student
			end
		else
			grp.each do |name|
				@students << name
			end
			grp
		end
	end

end
