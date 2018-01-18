# frozen_string_literal: true

class Sequence1 < OpenWFE::ProcessDefinition
  description 'a tiny sequence'
  sequence do
    participant 'admin'
    participant 'bob'
  end
end
