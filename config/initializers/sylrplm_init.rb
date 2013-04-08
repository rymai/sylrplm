require 'rufus/scheduler'

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

#p Rufus.parse_time_string '500'      # => 0.5
#p Rufus.parse_time_string '1000'     # => 1.0
#p Rufus.parse_time_string '1h'       # => 3600.0
#p Rufus.parse_time_string '1h10s'    # => 3610.0
#p Rufus.parse_time_string '1w2d'     # => 777600.0

#p Rufus.to_time_string 60              # => "1m"
#p Rufus.to_time_string 3661            # => "1h1m1s"
#p Rufus.to_time_string 7 * 24 * 3600   # => "1w"

scheduler = Rufus::Scheduler.start_new
puts 'Starting Scheduler'
scheduler.cron '0 21 * * 1-5' do
# every day of the week at 21:00
  Notification.notify_all(nil)
end

