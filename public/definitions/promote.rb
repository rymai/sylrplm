class PLMPromote < OpenWFE::ProcessDefinition

	description "Promotion objet PLM"

	set :v => "demandeur", :value => "${f:launcher}"
	set :v => "reviewer1", :value => "creator"
	set :v => "reviewer2", :value => "designer"
	set :v => "valideur", :value => "valider"
	#set :v => "publish", :value => "assistant"

	cursor do

		set :f => "comment_createur", :value => "comment demandeur"
		demandeur :activity =>  "Copier objet(s), Commenter"
		back :unless => '${f:comment_createur} != ""'

		plm Ruote::PlmParticipant, :task => "promote", :step => "init", :relation => "applicable"

		# taches paralleles, quorum=1
		set :f => "comment_relecteur", :value => "comment relecteur"
		concurrence :count => 2 do
			reviewer1 :activity => "-Copier objet(s) \n-Relire le document applicable\n-Commenter"
			reviewer2 :activity => "-Copier objet(s) \n-Relire le document applicable\n-Commenter"
		end
		back :unless => '${f:comment_relecteur} != ""'

		plm Ruote::PlmParticipant, :task => "promote", :step => "review", :relation => "reference"

		set :f => "ok", :value => "true"
		set :f => "comment_valideur", :value => "comment valideur"
		valideur :activity =>"commenter puis valider (ok=true) ou (ok=false) non ce document"
		back :if =>  '${f:ok} == false' && '${f:comment_valideur} == ""'
		# back to the reviewers if editor not happy
		rewind :unless =>  '${f:ok}'

		plm Ruote::PlmParticipant, :task => "promote", :step => "exec", :relation => "applicable"

	end
end