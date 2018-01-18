# frozen_string_literal: true

#
require 'rufus/scheduler'

#
# fichier de log specifique
#
logfile       = File.join(Rails.root, 'log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
# Install custom formatter!
NOLOGS = [
  'active_check',
  'add_objects_to_workitem',
  'ArWorkitem.create_from_wi',
  'build_column',
  'build_text',
  # "authorize",
  'check_init',
  'check_user',
  'clipboard',
  'def_user',
  'define_variables',
  'Filedriver',
  'find_paginate',
  'form_errors_for',
  'frozen?',
  'get_belong_method',
  'get_checkout',
  'get_fields',
  'get_languages',
  'get_model_from_controller',
  'get_controller',
  'get_model_type',
  'get_session_theme',
  'get_tree_definition',
  'get_tree_process',
  'get_type_values',
  'get_types_by_features',
  'get_themes',
  # "get_ui_columns",
  'h_render_fields',
  'h_type_values',
  'icone',
  'ident_plm',
  'index_',
  'initialize',
  'Link.initialize',
  'menu',
  'menus_feature',
  'mobile?',
  'plm_tree',
  'PlmServices.get_object',
  'PlmServices.get_propert',
  'relations_for',
  'render_fluo',
  'revisable?',
  'set_locale',
  'set_property',
  'to_s',
  'truncate_text',
  'Typesobject.get_types',
  'zip_stringio'

].freeze
# NOLOGS=[]
LOG.formatter = Classes::AppClasses::LogFormatter.new(NOLOGS)
# @logger.datetime_format = "%Y-%m-%d %H:%M:%S"
# DEBUG INFO WARN ERROR FATAL
LOG.level =
  case Rails.env
  when 'development'
    Logger::DEBUG
  when 'test', 'staging'
    Logger::WARN
  when 'production'
    Logger::ERROR
  else
    Logger::FATAL
  end
LOG.info('sylrplm') { 'Lancement SYLRPLM' }
LOG.progname = 'Constantes'
LOG.info { 'Constantes du module SYLRPLM:' }
SYLRPLM.constants.sort.each do |c|
  v = SYLRPLM.const_get(c)
  LOG.debug('Constante') { "#{c}\t\t= #{v}" }
end
LOG.info ('sylrplm') { "env=#{Rails.env.inspect} loglevel=#{LOG.level}" }
LOG.info ('sylrplm') { '--------------------------------------------' }

if (true)
	scheduler = Rufus::Scheduler.start_new
	puts '*** Starting Scheduler ***'
	# every day of the week at 21:00
	#scheduler.cron '0 21 * * 1-5' do
	# every 1 mn of each hour during the week
	job = scheduler.cron '*/1 7-21 * * 1-5' do
		Notification.notify_all(nil)
	#Rake.application[:notify].invoke
	#Rake::Task["notify"].invoke
	end
end
