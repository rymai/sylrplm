
class SylEditeur < OpenWFE::ProcessDefinition

  description "validation document"

  set :v => "createur", :value => "${f:launcher}"
  set :v => "reviewer1", :value => "relecteur1"
  set :v => "reviewer2", :value => "relecteur2"
  set :v => "valideur", :value => "chef"
  set :v => "publish", :value => "assistant"

  #set :v => "f" , :value => { :in => [{ :fields => '/^private_/', :remove => true }], :out => [{ :fields => '/^private_/', :restore => true },{ :fields => '/^protected_/', :restore => true }]}

  cursor do
    #filter "protected_priorite", :type => "number", :in => [1,2,3]
    #set :f => "protected_priorite", :value => 1
    #set :f => "protected_comment", :value => ""
    #jump :to => 'partdocument'
    
    set :f => "private_comment_createur", :value => "aaa"
    createur :activity => "Ajouter un commentaire svp"
    back :unless => '${f:private_comment_createur} != ""'
    #_redo :ref => 'createur', :unless => '${f:comment} != "" '
    
    wfdocument Ruote::WfDocument, :task=>"promote_init", :relation=>"applicable"
    
    # taches paralleles, quorum=1
    set :f => "private_comment_relecteur", :value => "bbb"
    concurrence :count => 1 do
      reviewer1 :activity => "Merci de relire ce document"
      reviewer2 :activity => "Merci de relire ce document"
    end
    back :unless => '${f:private_comment_relecteur} != ""'

    wfdocument Ruote::WfDocument, :task=>"promote_review", :relation=>"reference"
    
    set :f => "private_ok_for_publish", :value => "true"
    set :f => "private_comment_valideur", :value => "ccc"
    #participant :ref=> "valideur", :activity =>"Merci de valider ce document"
    valideur :activity =>"Merci de valider ce document"
    back :if =>  '${f:private_ok_for_publish} == false' && '${f:private_comment_valideur} == ""'
    # back to the reviewers if editor not happy
    rewind :unless =>  '${f:private_ok_for_publish}'

    ##publish 
    
    #participant 'document', Ruote::Sylrplm::WfDocument 
    wfdocument Ruote::WfDocument, :task=>"promote_exec"
    #part_document 'OpenWfe::PrintParticipant'

  end
end

