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

#mm hh jj MMM JJJ tâche
#mm représente les minutes (de 0 à 59)
#    hh représente l'heure (de 0 à 23)
#    jj représente le numéro du jour du mois (de 1 à 31)
#    MMM représente l'abréviation du nom du mois (jan, feb, ...) ou bien le numéro du mois (de 1 à 12)
#    JJJ représente l'abréviation du nom du jour ou bien le numéro du jour dans la semaine :
#        0 = Dimanche
#        1 = Lundi
#        2 = Mardi
#        ...
#        6 = Samedi
#        7 = Dimanche (représenté deux fois pour les deux types de semaine)
#Pour chaque valeur numérique (mm, hh, jj, MMM, JJJ) les notations possibles sont :
#    * : à chaque unité (0, 1, 2, 3, 4...)
#    5,8 : les unités 5 et 8
#    2-5 : les unités de 2 à 5 (2, 3, 4, 5)
#    */3 : toutes les 3 unités (0, 3, 6, 9...)
#   10-20/3 : toutes les 3 unités, entre la dixième et la vingtième (10, 13, 16, 19)
scheduler = Rufus::Scheduler.start_new
puts 'Starting Scheduler'
#scheduler.cron '0 21 * * 1-5' do
# every day of the week at 21:00
scheduler.cron '*/15 7-21 * * 1-5' do
# every 15 mn of each hour during the week 
  Notification.notify_all(nil)
end

