#
#   Reviser => a semi-automatic tool for student's projects evaluation
#
#   Copyright (C) 2015 Renan Strauss
#   Copyright (C) 2015 Yann Prono
#   Copyright (C) 2015 Romain Ruez
#   Copyright (C) 2015 Anthony Cerf
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
require '../lib/reviser'

require_relative 'my_component'
require_relative 'my_extension'

module MyApp
	include Reviser

	def self.run config_file = 'config.yml'
		#
		# Setup reviser
		#
		Reviser::setup config_file

		Reviser::register :extension => 'MyExtension'
		
		#
		# You can load any built-in component (archiver, organiser, checker, generator)
		# But be aware that they have to be ran in this order, and that
		# organiser takes input from archiver, checker from organiser and generator from checker
		# If you don't respect that, nothing will work.
		# But you can run your component at any step, this won't break the process.
		#
		Reviser::load :component => 'archiver'
		Reviser::load :component => 'organiser', :input_from => 'archiver'

		#
		# Tell reviser not to look for our component
		# in its core ones but to let us include it
		# ourselves instead
		#
		Reviser::load :component => 'my_component', :input_from => 'archiver', :local => true

		Reviser::load :component => 'checker', :input_from => 'organiser'
		Reviser::load :component => 'generator', :input_from => 'checker'

		#
		# Run reviser
		#
		Reviser::run
	end
end