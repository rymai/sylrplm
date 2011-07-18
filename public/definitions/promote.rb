
class PLMPromote < OpenWFE::ProcessDefinition

  description "Promotion objet PLM"

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
    
    set :f => "comment_createur", :value => "commentaire demandeur"
    demandeur :activity =>  "Mettez l objet(s) à promouvoir dans le presse papier, ajouter un commentaire puis valider cette tâche"
    back :unless => '${f:comment_createur} != ""'
    #_redo :ref => 'createur', :unless => '${f:comment} != "" '
    
    plm Ruote::PlmParticipant, :task=>"promote",:step=>"init"
    
    # taches paralleles, quorum=1
    set :f => "comment_relecteur", :value => "commentaire relecteur"
    concurrence :count => 1 do
      reviewer1 :activity => "-Mettez les objet(s) de référence dans le presse papier\n-Relire ce document\n-Mettre un commentaire\n-Valider cette tâche"
      reviewer2 :activity => "-Mettez les objet(s) de référence dans le presse papier\n-Relire ce document\n-Mettre un commentaire\n-Valider cette tâche"
    end
    back :unless => '${f:comment_relecteur} != ""'

    plm Ruote::PlmParticipant, :task=>"promote", :step=>"review"
    
    set :f => "ok", :value => "true"
    set :f => "comment_valideur", :value => "commentaire valideur"
    valideur :activity =>"Merci de commenter puis valider (ok=true) ou (ok=false) non ce document"
    back :if =>  '${f:ok} == false' && '${f:comment_valideur} == ""'
    # back to the reviewers if editor not happy
    rewind :unless =>  '${f:ok}'
    
    plm Ruote::PlmParticipant, :task=>"promote", :step=>"exec"

  end
end

