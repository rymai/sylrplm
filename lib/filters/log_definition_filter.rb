# frozen_string_literal: true

class LogDefinitionFilter
  def self.filter(controller)
    LOG.progname = "#{controller.controller_class_name}.#{controller.action_name}"
  end
end
