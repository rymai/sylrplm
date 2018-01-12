# frozen_string_literal: true

class SylEditeur < OpenWFE::ProcessDefinition
  description 'validation document'

  set v: 'createur', value: '${f:launcher}'
  set v: 'aztest', value: '${f:launcher}'
  set v: 'wfblock', value: '${f:launcher}'

  cursor do
    createur activity: 'Mettez l objet(s) à promouvoir dans le presse papier puis valider cette tâche'
    plm Ruote::PlmParticipant, task: 'promote', step: 'init'

    reviewer activity: 'Mettez les objet(s) de référence dans le presse papier puis valider cette tâche'
    plm Ruote::PlmParticipant, task: 'promote', step: 'review'

    #    wfblock

    # wfdocument Ruote::WfDocument, :task=>"valid"
    valider activity: 'Merci de valider ou non le(s) objets applicables'
    plm Ruote::PlmParticipant, task: 'promote', step: 'exec'

    creator activity: "Verifier que l'objet(s) a été promu"
  end
end
