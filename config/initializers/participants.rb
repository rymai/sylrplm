require 'ruote/sylrplm/participants'
require 'openwfe/participants/participants'



if RuotePlugin.ruote_engine
  puts "participants:loading participants"
  # only enter this block if the engine is running

  RuotePlugin.ruote_engine.register_participant "plm", Ruote::PlmParticipant

=begin
  RuotePlugin.ruote_engine.register_participant "wfblock" do |workitem|
    puts "wfbloc:********************************************"+workitem.inspect
    raise Exception, "exception generee par wfblock ******************"
  end
=end

  RuotePlugin.ruote_engine.reload
end

