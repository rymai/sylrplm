require 'classes/app_classes'

module SYLRPLM
  #include Classes::AppClasses::LogFormatter
  LOCAL_DEFAULT            = "fr"
  NOTIFICATION_DEFAULT     = 1
  TIME_ZONE_DEFAULT        = 1
  THEME_DEFAULT            = "blackwhite"
  NB_ITEMS_PER_PAGE        = 30
  ADMIN_GROUP_NAME         = 'admins'
  # chargement initial, voir PlmInitControllerModule
  DIR_DOMAINS = "#{RAILS_ROOT}/db/fixtures/domains/"
  DIR_ADMIN   = "#{RAILS_ROOT}/db/fixtures/admin/"
  ADMIN_MAIL  = "sylvere.coutable@laposte.net"
end

#
# fichier de log specifique
#
logfile       = File.join(File.dirname(__FILE__), '..', 'log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
LOG.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL ANY
LOG.formatter = Classes::AppClasses::LogFormatter.new  # Install custom formatter!
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
LOG.info("Lancement SYLRPLM")
LOG.info("logs dans: #{logfile}")
LOG.info("Constantes du module SYLRPLM:")
SYLRPLM.constants.each do |c|
  v = SYLRPLM.const_get(c)
  LOG.info("#{c}=#{v}")
end
LOG.info("--------------------------------------------")
