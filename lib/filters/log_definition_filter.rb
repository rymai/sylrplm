class LogDefinitionFilter
  def self.filter(controller)
    LOG.progname = "#{controller.controller_name}.#{controller.action_name}"
  end
end
