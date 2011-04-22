class SylEditeur < OpenWFE::ProcessDefinition

  description "validation document"

  set :v => "createur", :value => "${f:launcher}"
  set :v => "aztest", :value => "${f:launcher}"
  set :v => "wfblock", :value => "${f:launcher}"

  cursor do

    createur :activity=>"Mettez l objet(s) de ref dans le presse papier"
    
    wfdocument Ruote::WfDocument, :task=>"init"

    #    wfblock

    #wfdocument Ruote::WfDocument, :task=>"valid"
    wfdocument Ruote::WfDocument, :task=>"promote"

    aztest

  end

end