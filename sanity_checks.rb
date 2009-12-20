# Copyright (C) 2009  Ryan Stenhouse 
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

class SanityChecks

  cattr_accessor :errors

  def self.jobby_rails_installed?
    return true if File.exists?(File.dirname(__FILE__) + "/.jobbyRailsInstalled")
    @@errors = []
    jobby_jobs_table_exists
    javascripts_are_where_they_should_be
    if (errors.nitems == 0)
      system("touch '#{File.dirname(__FILE__)}/.jobbyRailsInstalled'")
      return true
    else
      return false
    end
  end

  def self.jobby_jobs_table_exists
    ActiveRecord::Base.establish_connection(YAML::load(IO.read(RAILS_ROOT + '/config/database.yml'))[RAILS_ENV.downcase])
    if not ActiveRecord::Base.connection.tables.include?('jobby_jobs') 
      @@errors << "'jobby_jobs' table not found. Run migration!"
    end
  end

  def self.javascripts_are_where_they_should_be
    if not File.exists?("#{RAILS_ROOT}/public/javascripts/jobby_notifications.js")
      @@errors << "Jobby Notifications is not in rails Javascripts Directory"
    end
    if not File.exists?("#{RAILS_ROOT}/public/javascripts/jquery.gritter.min.js")
      @@errors << "Gritter JQuery plugin is not in rails Javascripts Directory"
    end
    if not File.exists?("#{RAILS_ROOT}/public/javascripts/jquery.js")
      @@errors << "JQuery is not in rails Javascripts Directory"
    end
    if not File.exists?("#{RAILS_ROOT}/public/javascripts/jquery.timers.js")
      @@errors << "Timer JQuery plugin is not in rails Javascripts Directory"
    end
  end

  def self.error_banner
    return <<-ERR

Warning! Jobby Rails has not been correctly installed!    
------------------------------------------------------

After installing the plugin, there is a rake task which
needs to be run to make sure the required assets are
copied accross and all manner of other fun things are
set up.

If you aren't bothered about the specific problem, run
rake jobby_rails:install and it'll do the steps that
need to be completed to install.

  ERR
  
  end

end
