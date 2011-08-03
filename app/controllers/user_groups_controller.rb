#--
# Copyright (c) 2008-2009, John Mettraux, jmettraux@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
# Made in Japan.
#++

#
# This RESTful resource has no 'edit' nor 'new' view. User 'groups' for
# interaction via HTML.
#
class UserGroupsController < ApplicationController

  ###before_filter :login_required
  # GET /user_groups
  # GET /user_groups.xml
  #
  def index

    @current_user_groups = UserGroup.find(:all)

    respond_to do |format|
      format.html { redirect_to :controller => :groups, :action => :index }
      format.xml { render :xml => @current_user_groups }
    end
  end

  # GET /user_groups/1
  # GET /user_groups/1.xml
  #
  def show

    @current_user_group = UserGroup.find(params[:id])

    respond_to do |format|
      format.html do
        redirect_to(
          :controller => :groups,
          :action => :show,
          :id => @current_user_group.group_id)
      end
      format.xml { render :xml => @current_user_group }
    end
  end

  # POST /user_groups
  # POST /user_groups.xml
  #
  def create

    @current_user_group = UserGroup.new(params[:user_group])

    respond_to do |format|

      if @current_user_group.save

        flash[:notice] = t(:ctrl_object_created, :typeobj => t(:ctrl_group), :ident => "#{@current_user_group.user.login}-#{@current_user_group.group.name}")
        format.html do
          if request.env['HTTP_REFERER']
            redirect_to :back
          else
            redirect_to(
              :controller => :groups,
              :action => :show,
              :id => @current_user_group.group_id)
          end
        end
        format.xml do
          render(
            :xml => @current_user_group,
            :status => :created,
            :location => @current_user_group)
        end

      else
        flash[:notice] = t(:ctrl_object_not_created, :typeobj => t(:ctrl_group), :msg => nil)

        format.html {
          render :controller => :groups, :action => :index }
        format.xml {
          render :xml => @current_user_group.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /user_groups/1
  # DELETE /user_groups/1.xml
  #
  def destroy

    @current_user_group = UserGroup.find(params[:id])
    @current_user_group.destroy

    respond_to do |format|
      format.html do
        if request.env['HTTP_REFERER']
          redirect_to :back
        else
          redirect_to :controller => :user_groups, :action => :index
        end
      end
      format.xml do
        head :ok
      end
    end
  end

  protected

  #
  # Only an admin can create or delete a user-group association.
  #
  def authorized?

    @current_user && @current_user.is_admin?
  end
end
