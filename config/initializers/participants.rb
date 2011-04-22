require 'ruote/sylrplm/participants'
require 'openwfe/participants/participants'


if RuotePlugin.ruote_engine
  
  # only enter this block if the engine is running

  # This is a test participant
  #
  # Feel free to comment it out / erase it
  #
  RuotePlugin.ruote_engine.register_participant 'herr_murphy' do |workitem|
    raise "dead beef !*******************************************************"
  end

  RuotePlugin.ruote_engine.register_participant "wfdocument", Ruote::WfDocument

  #  RuotePlugin.ruote_engine.register_participant "wfblock" do |workitem|
  #    puts "wfbloc:********************************************"+workitem.inspect
  #    raise Exception, "exception generee par wfblock ******************"
  #  end
  #RuotePlugin.ruote_engine.register_participant :wfpart, Ruote::WfPart

  #RuotePlugin.ruote_engine.reload
end

