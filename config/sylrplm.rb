require 'classes/app_classes'


#
# fichier de log specifique
#
logfile       = File.join(File.dirname(__FILE__),'..','log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
LOG.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL ANY
LOG.formatter = Classes::AppClasses::LogFormatter.new  # Install custom formatter!
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
LOG.info("Lancement SYLRPLM")
LOG.info("logs dans: #{logfile}")
LOG.info("Constantes du module SYLRPLM:")
SYLRPLM.constants.each do |c|
  v=SYLRPLM.const_get(c)
  LOG.info("#{c}=#{v}")
end
LOG.info("--------------------------------------------")


