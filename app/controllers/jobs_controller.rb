# Copyright (C) 2009 Ryan Stenhouse
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

class JobsController < ApplicationController

  def index
    @my_jobs = Jobby::Job.find(:all, :conditions => [ 'user_id = ?', session[:user_id] ], :order => "started_at DESC")
    @other_jobs = Jobby::Job.find(:all, :conditions => [ 'user_id != ?', session[:user_id] ], :order => "started_at DESC" )
  end

  def status
    @job = Jobby::Job.find(params[:id].to_i)
    if request.xhr?
      render :text => @job.to_json  
    else
      if @job.running?
        @refresh = true
      else
        @refresh = false
      end
    end
  end


end
