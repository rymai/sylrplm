# frozen_string_literal: true

require 'classes/controller'
require 'will_paginate'

class MainController < ApplicationController
  # access_control(Access.find_for_controller(controller_name.classify))
  skip_before_filter :authorize, :check_user
  # def infos
  #  request.env["PATH_INFO"] +":"+__FILE__+":"+__LINE__.to_s
  # end
  def index
    fname = "#{self.class.name}.#{__method__}"
    # LOG.info(fname){"params=#{params.inspect}"}
    if params[:domain].blank?
      @domains = Controller.get_domains
      @directory = ::SYLRPLM::VOLUME_DIRECTORY_DEFAULT
    else
      # creation du domaine demande: status et types d'objets
      st = Controller.init_db(params)
      flash[:notice] = t(:ctrl_init_done)
    end
    @themes = get_themes(@theme)
    unless params[:theme].nil?
      @theme = params[:theme]
      if @current_user.nil?
        session[:theme] = @theme
      else
        @current_user.theme = @theme
        st = @current_user.save
      end
    end
    @theme = 'white' if @theme.nil?
    unless params[:locale].nil?
      set_locale
      unless @current_user.nil?
        @current_user.language = params[:locale]
        st = @current_user.save
      end
    end
    set_domain unless params[:domain].nil?

    unless @current_user.nil?
      opts = { order: 'dispatch_time DESC' }
      opts[:conditions] = { store_name: @current_user.store_names }
      opts[:page] = (params[:page].nil? ? PlmServices.get_property(:NB_ITEMS_PER_PAGE).to_i : params[:page])
      # TODO: rails4
      # @workitems = Ruote::Sylrplm::ArWorkitem.paginate_by_params([# parameter_name[, column_name] 'wfid',[ 'workflow', 'wf_name' ],	[ 'store', 'store_name' ],	[ 'participant', 'participant_name' ]],params,opts)
    end
    # LOG.debug(fname) {"@workitems=#{@workitems.inspect}"}
    respond_to do |format|
      @main = true
      format.html # index.html.erb
    end
  end

  def how_to
    fname = "#{self.class.name}.#{__method__}"
    @files = {}
    LOG.debug(fname) { "RAILS_ROOT=#{Rails.root}" }
    urlbase = "#{Rails.root}/public/how_to"
    Dir.new(urlbase.to_s).entries.each do |doc|
      next if doc == '.' || doc == '..'
      LOG.debug(fname) { "doc=#{doc}" }
      @files[doc] = {}
      mdlfiles = []
      docfiles = []
      Dir.new("#{urlbase}/#{doc}").entries.each do |file|
        unless file == '.' || file == '..'
          if file == 'files'
            Dir.new("#{urlbase}/#{doc}/#{file}").entries.each do |mdlfile|
              unless mdlfile == '.' || mdlfile == '..'
                mdlfiles << "#{file}/#{mdlfile}"
              end
            end
          else
            docfiles << file
          end
        end
        LOG.debug(fname) { "file=#{file}" }
        @files[doc][:docfiles] = docfiles
        @files[doc][:mdlfiles] = mdlfiles
      end
    end
    LOG.debug(fname) { "@files=#{@files}" }
  end

  def helpgeneral
    # puts " helpgeneral"
    respond_to do |format|
      format.html # helpgeneral.html.erb
    end
  end
end
