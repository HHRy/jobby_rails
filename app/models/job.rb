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

require 'activerecord'

module Jobby
  class Job < ActiveRecord::Base
    
    set_table_name :jobby_jobs

    belongs_to :user

    attr_accessor :log

    #  Returns 3 jobs for the specific user, this is used by the Jobby Notification Area in order
    #  to show only the three most important (IE - Running and Newly Finished) Jobs submitted by
    #  the user within the last 4 hours.
    #
    def self.jobs_for_user(user_id)
      find(:all, :conditions => [ 'user_id = ? AND created_at > ?', user_id, cut_off_time ], :order => "id DESC", :limit => 3)
    end 

    #  Returns the count of jobs submitted by the specified User.
    #
    def self.count_jobs_for_user(user_id)
      count(:id, :conditions =>  [ 'user_id = ?', user_id ])
    end

    #  Adds a job to the jobby_jobs table and returns the created Job object. 
    #  Expects the underscores version of the freelancer's name, minus the text
    #  'freelancer'.
    #
    def self.add(freelancer, path_to_freelancers, time_to_live, priority, *args)
      job = self.new
      job.path_to_freelancers = File.expand_path(path_to_freelancers)
      job.freelancer = freelancer.to_s
      job.time_to_live = time_to_live
      job.args = args
      job.status = "NEW"
      job.progress_message = "Preparing to execute..."
      job.save!
      return job
    end
    
    # Pulls out the next job which is currently NEW for execution. As this method is only
    # used by the Dispatcher to run the Job, the stus is automatically updated to RUNNING.
    # Returns nil if there are no jobs.
    #
    def self.next
      job = self.find(:first, :conditions => [ 'status = "NEW"' ], :order => :priority)
      job.update_attributes(:status => "RUNNING", :started_at => Time.now) unless job.nil?
      return job
    end

    # Is this job running?
    #
    def running?
      self.status == 'RUNNING'
    end
    
    # Four ours ago, formatted as a MySQL DateTime string.
    #
    def self.cut_off_time
      4.hours.ago.strftime("%Y-%m-%d %H:%M:%S")
    end

    # Is this job done?
    #
    def done?
      self.status == 'DONE'
    end

    # Is this job new?
    #
    def new?
      self.status == 'NEW'
    end

    # Parses out the message from the progress_message string.
    #
    def message
      if progress_message.include?('||')
        m = progress_message.split('||').last    
        if using_split_progress?
          m = m.split('***').first
        end
        return m
      else
        progress_message
      end
    end
    
    # Parses out the overall number of stages for this task from the
    # progress_message string.
    #
    def overall_total_stages
      return 1 if done?
      if progress_message.include?('||')
        BigDecimal(progress_message.split('||')[1])
      else
        1
      end
    end
    
    # Parses out the overall current stage for this task from the
    # progress_message string.
    #
    def overall_current_stage
      return 1 if done?
      if progress_message.include?('||')
        BigDecimal(progress_message.split('||').first)
      else
        1
      end
    end

    #  Works out the overall completion percentage, based on the overall_current_stage
    #  and overall_total_stage. Also adjusets based on stage_percentage if set.
    #
    def overall_percentage
      percent = ((overall_current_stage / overall_total_stages)*100).round_to(2)
      if using_split_progress?
        one_part = 100 / overall_total_stages
        difference = ((one_part / 100) * stage_percentage)
        percent += difference
      end
      return percent.round_to(2)
    end

    #  Determines from the progress_message string if we intend to show two progress bars or not.
    #
    def using_split_progress?
      (progress_message.include?('***') && progress_message.include?('^^'))
    end
  
    # If we are using_split_progress?, parses out the current step we're on for this stage.
    #
    def stage_current_step
      return 1 if done?
      if using_split_progress?
        BigDecimal(progress_message.split('***').last.split('^^')[0])
      else
        1
      end
    end

    # If we are using_split_progress?, parses out the total steps for this stage.
    #
    def stage_total_steps
      return 1 if done?
      if using_split_progress?
        BigDecimal(progress_message.split('***').last.split('^^')[1])
      else
        2
      end
    end
    
    # Calculates the current stage's percentage of completion.
    #
    def stage_percentage
      ((stage_current_step / stage_total_steps)*100).round_to(2)
    end

    # Unmarshalls the arguments saved for this job.
    #
    def args
      unless @unmasrshalled_args
        @unmarshalled_args = Marshal.load(read_attribute(:args)).flatten
      end
      @unmarshalled_args
    end
    
    # Marshalls the value(s) passed in and saves them in the database.
    #
    def args=(*something)
      write_attribute(:args, Marshal.dump(something))
    end

    # Returns a simple JSON representation of the current Job.
    #
    def to_json
      if !running?
        json = "{jobId: '#{id}', jobStatus: '#{status}', title: '#{freelancer.titleize}', message: '#{message.gsub("\n",'').gsub("\r",'').gsub("'",'"')}'}"
      else
        mess = "#{message}<div class=\"weeOuterBar\" style=\"width:100%\"><div class=\"weeInnerBar\" style=\"width:#{overall_percentage}%;\">#{overall_percentage}</div></div>".gsub("'",'"').gsub("\n",'').gsub("\r",'')
        json = "{jobId: '#{id}', jobStatus: '#{status}', title: '#{freelancer.titleize}', message: '#{mess.strip}'}"
      end
      return json
    end

  end
end
