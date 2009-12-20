# Copyright (C) 2008 - 2009 Ryan Stenhouse & Mark Somerville
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
  
  #  The Freelancer class forms the basis for you to write your own Freelancers to allow
  #  Work to be handed off from Rails to Jobby. 
  #
  class Freelancer
    attr_reader :job
    
    #  Takes in the Job object that this Freelancer is instanstiated by.
    #
    def initialize(job)
      @job = job
      @progress_updated_at = Time.now
    end
    
    # Saves the progress message with the Job, but only does so once every five seconds to
    # avoid thrashing the database.
    #
    def progress_message=(message)
      @job.progress_message = message
      if @progress_updated_at > 5.seconds.ago
        @job.update_attribute(:progress_message, message)
        @progress_updated_at = Time.now
      end
    end
    
    # Implement this in your own subclasses for your Freelancer to be able to do anything.
    #
    def work
      raise "Sub-classes of Jobby::Freelancer should implement a work method."
    end
    
    # Called automatically by JobbyRails, wraps the work method in exception handling and ensures
    # progress message updates, job status updates and logging all happen.
    #
    def go_to_work
      begin
        @job.log.info("Freelancer: Getting to Work") unless @job.log.nil?
        @job.update_attributes(:started_at => Time.now, :status => "RUNNING", :progress_message => "Starting job")
        work
        @job.save # this is to ensure the final progress message is saved
        @job.log.info("Freelancer: Work Completed Successfully") unless @job.log.nil?
        @job.update_attribute(:status, "DONE")
      rescue Exception => exception
        @job.log.error("Freelancer: Failed With Error: #{exception}\n\n#{exception.backtrace.join("\n")}") unless @job.log.nil?
        mark_job_as_failed(exception)
      end
    end
    
    #  Sets the jobs Status to ERROR and logs the reason why.
    #
    def mark_job_as_failed(error = nil)
      @job.update_attribute(:status, "ERROR")
      if error
        @job.update_attribute(:progress_message, "Job Failed: \"#{error}\".")
      end
    end
  end
end
