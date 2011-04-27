require 'classes/app_classes'
module SYLRPLM
#include Classes::AppClasses::LogFormatter
  VOLUME_DIRECTORY_DEFAULT="C:\\sylrplm_data"
  LOCAL_DEFAULT="fr"
  THEME_DEFAULT="blackwhite" 
  NB_ITEMS_PER_PAGE=30
  ADMIN_GROUP_NAME = 'admins'

end
#
# fichier de log specifique
#
logfile           = File.join(File.dirname(__FILE__),'..','log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
LOG.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL ANY
LOG.formatter = Classes::AppClasses::LogFormatter.new  # Install custom formatter!
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
LOG.info("lancement SYLRPLM")
