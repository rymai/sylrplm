class PLMRevise < OpenWFE::ProcessDefinition
	description "Revision objet PLM"

	set :v => "demandeur", :value => "${f:launcher}"
	set :v => "valideur", :value => "chef de projet"

	#set :v => "f" , :value => { :in => [{ :fields => '/^private_/', :remove => true }], :out => [{ :fields => '/^private_/', :restore => true },{ :fields => '/^protected_/', :restore => true }]}

	cursor do
	#filter "protected_priorite", :type => "number", :in => [1,2,3]
	#set :f => "protected_priorite", :value => 1
	#set :f => "protected_comment", :value => ""
	#jump :to => 'partdocument'

		set :f => "comment_createur", :value => "commentaire demandeur"
		demandeur :activity =>  "Mettez l objet(s) à réviser dans le presse papier, ajouter un commentaire puis valider cette tâche"
		back :unless => '${f:comment_createur} != ""'
		#_redo :ref => 'createur', :unless => '${f:comment} != "" '

		plm Ruote::PlmParticipant, :task=>"revise",:step=>"init", :relation => "applicable"

		set :f => "ok", :value => "true"
		set :f => "comment_valideur", :value => "commentaire valideur"
		valideur :activity => "Commentez puis validez (true) ou non (false)"
		back :if =>  '${f:ok} == false' && '${f:comment_valideur} == ""'
		# back to the reviewers if editor not happy
		rewind :unless =>  '${f:ok}'

		plm Ruote::PlmParticipant, :task=>"revise", :step=>"exec", :relation => "applicable"

	end

end