require 'classes/app_classes'
require 'controllers/plm_event'
require 'controllers/plm_object_controller_module'
require 'controllers/plm_init_controller_module'
require 'models/plm_object'
require 'models/sylrplm_common'
require 'ruote_routing'
require 'ruote/sylrplm/participants'
require 'rubygems'
require 'rufus/scheduler'

# p Rufus.parse_time_string '500'      # => 0.5
# p Rufus.parse_time_string '1000'     # => 1.0
# p Rufus.parse_time_string '1h'       # => 3600.0
# p Rufus.parse_time_string '1h10s'    # => 3610.0
# p Rufus.parse_time_string '1w2d'     # => 777600.0
#
# p Rufus.to_time_string 60              # => "1m"
# p Rufus.to_time_string 3661            # => "1h1m1s"
# p Rufus.to_time_string 7 * 24 * 3600   # => "1w"

scheduler = Rufus::Scheduler.start_new
scheduler.cron '0 21 * * 1-5' do
  # every day of the week at 21:00
  puts 'scheduler'
  Notification.notify
end
