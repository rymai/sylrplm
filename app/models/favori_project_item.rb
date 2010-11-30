class FavoriProjectItem
  attr_reader :project
  def initialize(project)
    @project=project
  end
  def title
    @project.title    
  end
end