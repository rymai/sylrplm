class ValidateUser < OpenWFE::ProcessDefinition

  description "Validation of a PLM user"

  set :v => "admin", :value => "admin"
  set :v => "valider", :value => "admin"
  
  cursor do

    set :f => "comment", :value => "comment"
    admin :activity =>  "Edit user to add projects, roles and groups"
    back :if => '${f:comment} == ""'

    plm Ruote::PlmParticipant, :task => "validate_user", :step => "init", :relation => "applicable"
    
 
    set :f => "ok", :value => "true"
    set :f => "comment_valider", :value => "comment valider"
    valider :activity =>"Comment and validate (ok=true) ou (ok=false) non ce user"
 		plm Ruote::PlmParticipant, :task => "validate_user", :step => "exec", :relation => "applicable"

    back :if =>  '${f:ok} == false' && '${f:comment_valideur} == ""'
    # back to the reviewers if editor not happy
    rewind :unless =>  '${f:ok}'


  end
end