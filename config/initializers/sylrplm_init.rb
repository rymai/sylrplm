

#
# fichier de log specifique
#
logfile       = File.join(Rails.root, 'log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
# Install custom formatter!
LOG.formatter = Classes::AppClasses::LogFormatter.new
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
#DEBUG INFO WARN ERROR FATAL
LOG.level  = case Rails.env
when "development"
  Logger::DEBUG
when "test"
  Logger::DEBUG
when "production"
  Logger::ERROR
end
LOG.info("sylrplm"){"Lancement SYLRPLM"}
LOG.progname="Constantes"
LOG.info {"Constantes du module SYLRPLM:"}
SYLRPLM.constants.sort.each do |c|
  v = SYLRPLM.const_get(c)
  LOG.debug("Constantes"){"#{c}\t\t= #{v}"}
end
LOG.info ("sylrplm"){"env=#{Rails.env.inspect} loglevel=#{LOG.level}"}
LOG.info ("sylrplm"){"--------------------------------------------"}


