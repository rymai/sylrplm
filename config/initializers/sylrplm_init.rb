#
require 'rufus/scheduler'

#
# fichier de log specifique
#
logfile       = File.join(Rails.root, 'log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
# Install custom formatter!
NOLOGS=["Typesobject.get_types",
	"PlmServices.get_propert",
	"PlmServices.get_object",
	"menus_feature",
	"get_type_values",
	"get_types_by_features",
	"get_fields",
	"find_paginate",
	"get_themes",
	"define_variables",
	"set_locale",
	"to_s",
	"get_session_theme",
	"check_init",
	"menu",
	"active_check",
	"get_model_from_controller",
	"ident_plm",
	"plm_tree",
	"frozen?",
	"form_errors_for",
	"h_type_values",
	"relations_for",
	"get_model_type",
	"set_property",
	"revisable?",
	#"authorize",
	"initialize",
	"def_user",
	"check_user",
	"render_fluo",
	#"add_objects_to_workitem",
	#"ArWorkitem.create_from_wi",
	"h_render_fields",
	#"index_",
	"get_tree_process",
	"get_checkout",
	"get_tree_definition|tree=",
	"get_languages"
]
#NOLOGS=[]
LOG.formatter = Classes::AppClasses::LogFormatter.new(NOLOGS)
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
#DEBUG INFO WARN ERROR FATAL
LOG.level  = case Rails.env
when "development"
	Logger::DEBUG
when "test"
	Logger::ERROR
when "production"
	Logger::ERROR
end
LOG.info("sylrplm"){"Lancement SYLRPLM"}
LOG.progname="Constantes"
LOG.info {"Constantes du module SYLRPLM:"}
SYLRPLM.constants.sort.each do |c|
	v = SYLRPLM.const_get(c)
	LOG.debug("Constante"){"#{c}\t\t= #{v}"}
end
LOG.info ("sylrplm"){"env=#{Rails.env.inspect} loglevel=#{LOG.level}"}
LOG.info ("sylrplm"){"--------------------------------------------"}

if (false)
	scheduler = Rufus::Scheduler.start_new
	puts '*** Starting Scheduler ***'
	# every day of the week at 21:00
	#scheduler.cron '0 21 * * 1-5' do
	# every 10 mn of each hour during the week
	job = scheduler.cron '*/10 7-21 * * 1-5' do
		Notification.notify_all(nil)
	#Rake.application[:notify].invoke
	#Rake::Task["notify"].invoke
	end
end

