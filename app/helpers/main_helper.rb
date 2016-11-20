require 'help_helper'
require "browser"


module MainHelper

	include HelpHelper

	def mobile?
			fname="#{self.class.name}.#{__method__}"
			browser = Browser.new("Some User Agent", accept_language: "en-us")
			LOG.debug(fname){"platform=#{browser.platform} mobile?=#{browser.device.mobile?}"}
			browser.device.mobile?
			true
	end


end
