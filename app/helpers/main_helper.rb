require 'help_helper'

#require "browser"

module MainHelper

	include HelpHelper
	def mobile?
		fname="#{self.class.name}.#{__method__}"
		#browser = Browser.new("Some User Agent", accept_language: "en-us")
		#LOG.debug(fname){"platform=#{browser.platform} mobile?=#{browser.device.mobile?}"}
		#LOG.debug(fname){"browser.device=#{browser.device.inspect}"}
		#LOG.debug(fname){"browser.to_s=#{browser.to_s}"}
		#LOG.debug(fname){"browser.chrome?=#{browser.chrome?} browser.firefox?=#{browser.firefox?} browser.ie?=#{browser.ie?} browser.opera?=#{browser.opera?} browser.safari?=#{browser.safari?}"}

		#browser.device.mobile?

		user_agent = UserAgent.parse(request.env["HTTP_USER_AGENT"])

		LOG.debug(fname){"user_agent=#{user_agent.inspect}"}
		LOG.debug(fname){"application=#{user_agent.application}"}
		LOG.debug(fname){"browser=#{user_agent.browser}"}
		LOG.debug(fname){"version=#{user_agent.version}"}
		LOG.debug(fname){"mobile?=#{user_agent.mobile?}"}
		LOG.debug(fname){"platform=#{user_agent.platform}"}
		LOG.debug(fname){"os=#{user_agent.os}"}

		#user_agent.application %> # Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:22.0)
		#Browser: <%= user_agent.browser %> # Firefox
		#Version: <%= user_agent.version %> # 22.0
		#Platform: <%= user_agent.platform %> # Macintosh
		#Mobile: <%= user_agent.mobile? %> # False
		#OS: <%= user_agent.os %> # OS X 10.8
		user_agent.mobile?
	end

end
