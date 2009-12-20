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

require "#{File.dirname(__FILE__)}/../app/models/job.rb"
module Jobby
  # The Dispatcher starts off the next job available to run from the jobby_jobs
  # table, this is envoked by the jobby_rails by Jobby it's self.
  #
  class Dispatcher
    
    # Takes an optional Logger object to ensure the Job pulled out from the Database
    # has full access to a Logger. It pulls out the Freelancer's name from the database,
    # instansiates it and runs it.
    #
    def self.dispatch_job(log = nil)
      job = Jobby::Job.next
      unless log.nil?
        log.info "Dispatcher Kicked off for job #{job.id} - #{job.freelancer}"
        job.log = log
      end
      require "#{job.path_to_freelancers}/#{job.freelancer}_freelancer"
      freelancer_class = job.freelancer+"_freelancer"
      freelancer_class = freelancer_class.classify.constantize
      log.info("Sending the freelancer #{freelancer_class.to_s} to work...") unless log.nil?
      freelancer_class.new(job).go_to_work
    end
  end
end
