# Copyright (C) 2008, 2009  Mark Somerville & Ryan Stenhouse
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

module Jobby
  
  # Methods stored here will be added to ActionController::Base to make them available
  # to all controllers.
  #
  module Methods

    # Jobby Rails working like BackgroundJob
    # 
    def jobby_rails(&block)
      job = Jobby::Job.new
      job.time_to_live = 600
      job.path_to_freelancers = JOBBY_FREELANCERS_PATH
      job.status = 'NEW'
      job.progress_message = "Preparing to execute..."
      yield job
      job.save!
      jobby :ruby => "#{plugin_path}/bin/jobby_rails", :"max-children" => 5
      return job
    end

    # jobby is an interface to the command-line jobby client, and really just munges your input
    # into the correct parameters for the jobby client to parse and do stuffs with.
    #
    # Valid options are:
    #   - :input
    #   - :ruby
    #   - :command
    #   - :"max-children"
    #   - :socket
    #   - :log
    #   - :prerun
    #
    def jobby(options = {})
      default = { :input => 'none', :ruby => "#{plugin_path}/bin/jobby_rails", :command => nil, :"max-children" => 5, :socket => "#{RAILS_ROOT}/tmp/sockets/jobby_rails.socket", :log => "#{RAILS_ROOT}/log/jobby_rails.log", :prerun => "#{RAILS_ROOT}/config/environment.rb" }
      options = default.merge(options)
      command = "jobby"
      options.each { |k,v| next if v.nil?; v = "'#{v}'" if k == :input; command += " --#{k} #{v}"; }
      fork { exec(command) }
    end

    # Does what it says on the tin!
    # 
    def fetch_job(job_id)
      Jobby::Job.find(job_id)
    end

    def fetch_status_for(job_id)
      fetch_job(job_id).status
    end

    def fetch_message_for(job_id)
      fetch_job(job_id).progress_message
    end

    private

    # Gives us the path the plugin is installed to, since not everyone will be keeping
    # it in the same place.
    #
    def plugin_path 
      File.expand_path(File.dirname(__FILE__) + "/../")
    end

  end
end
