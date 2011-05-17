
class SylEditeur < OpenWFE::ProcessDefinition

  description "validation document"

  set :v => "demandeur", :value => "${f:launcher}"
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
    
    set :f => "private_comment_createur", :value => "commentaire demandeur"
    demandeur :activity =>  "Mettez l objet(s) à promouvoir dans le presse papier, ajouter un commentaire puis valider cette tâche"
    back :unless => '${f:private_comment_createur} != ""'
    #_redo :ref => 'createur', :unless => '${f:comment} != "" '
    
    plm Ruote::PlmParticipant, :task=>"promote",:step=>"init"
    
    # taches paralleles, quorum=1
    set :f => "private_comment_relecteur", :value => "commentaire relecteur"
    concurrence :count => 1 do
      reviewer1 :activity => "-Mettez les objet(s) de référence dans le presse papier\n-Relire ce document\n-Mettre un commentaire\n-Valider cette tâche"
      reviewer2 :activity => "-Mettez les objet(s) de référence dans le presse papier\n-Relire ce document\n-Mettre un commentaire\n-Valider cette tâche"
    end
    back :unless => '${f:private_comment_relecteur} != ""'

    plm Ruote::PlmParticipant, :task=>"promote", :step=>"review"
    
    set :f => "private_ok_for_publish", :value => "true"
    set :f => "private_comment_valideur", :value => "commentaire valideur"
    #participant :ref=> "valideur", :activity =>"Merci de valider ce document"
    valideur :activity =>"Merci de valider ce document"
    back :if =>  '${f:private_ok_for_publish} == false' && '${f:private_comment_valideur} == ""'
    # back to the reviewers if editor not happy
    rewind :unless =>  '${f:private_ok_for_publish}'

    ##publish 
    
    #participant 'document', Ruote::Sylrplm::WfDocument 
    plm Ruote::PlmParticipant, :task=>"promote", :step=>"exec"
    #part_document 'OpenWfe::PrintParticipant'

  end
end

