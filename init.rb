# Copyright (C) 2008, 2009 Ryan Stenhouse & Mark Somerville
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

# Calculate RAILS_ROOT on the off chance that it isnt defined, we need
# this to get the Production database configuration.
#
if not defined? RAILS_ROOT
  RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../../') rescue nil
end

# Sanity Checks - Make sure that JobbyRails has been installed!
#
require File.dirname(__FILE__) + '/sanity_checks.rb'
unless SanityChecks.jobby_rails_installed?
  puts SanityChecks.error_banner
  SanityChecks.errors.each do |error|
    puts "\n  *  #{error}"
  end
  puts "\n\nWill Now Exit!\n\n"
  exit(-1)
end

# Set the Freelancer's path
#
JOBBY_FREELANCERS_PATH = RAILS_ROOT + '/lib/freelancers'
unless File.exists?(JOBBY_FREELANCERS_PATH)
  `mkdir #{JOBBY_FREELANCERS_PATH}`
end


# Pull in the required code
#
require File.dirname(__FILE__) + "/lib/jobby_dispatcher.rb"
require File.dirname(__FILE__) + "/lib/freelancer.rb"
require File.dirname(__FILE__) + "/lib/methods.rb"

# Job will always connect to the #{RAILS_ENV} database. This won't impact on any
# of the other models.
#
begin
  Jobby::Job.establish_connection(YAML::load(IO.read(RAILS_ROOT + '/config/database.yml'))[RAILS_ENV.downcase])
rescue Exception => error
  puts <<-TXT

    The Jobby-Rails Plugin failed to load because it couldn't establish
    a connection to your #{RAILS_ENV} database environment.

    The exact exception raised was:
      #{error}

  TXT
  exit(-1)
end

# Give all the actions our methods
#
ActionController::Base.send(:include, Jobby::Methods)

puts "=> PCCL Rails / Jobby Interface Loaded"
