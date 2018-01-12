# frozen_string_literal: true

require 'help_helper'

# require "browser"

module MainHelper
  include HelpHelper

  def mobile?
    fname = "#{self.class.name}.#{__method__}"
    # browser = Browser.new("Some User Agent", accept_language: "en-us")
    # LOG.debug(fname){"platform=#{browser.platform} mobile?=#{browser.device.mobile?}"}
    # LOG.debug(fname){"browser.device=#{browser.device.inspect}"}
    # LOG.debug(fname){"browser.to_s=#{browser.to_s}"}
    # LOG.debug(fname){"browser.chrome?=#{browser.chrome?} browser.firefox?=#{browser.firefox?} browser.ie?=#{browser.ie?} browser.opera?=#{browser.opera?} browser.safari?=#{browser.safari?}"}
    # browser.device.mobile?
    user_agent = UserAgent.parse(request.env['HTTP_USER_AGENT'])
    LOG.debug(fname) { "user_agent=#{user_agent.inspect}" }
    LOG.debug(fname) { "application=#{user_agent.application}" }
    LOG.debug(fname) { "browser=#{user_agent.browser}" }
    LOG.debug(fname) { "version=#{user_agent.version}" }
    LOG.debug(fname) { "mobile?=#{user_agent.mobile?}" }
    LOG.debug(fname) { "platform=#{user_agent.platform}" }
    LOG.debug(fname) { "os=#{user_agent.os}" }
    # user_agent.application %> # Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:22.0)
    # Browser: <%= user_agent.browser %> # Firefox
    # Version: <%= user_agent.version %> # 22.0
    # Platform: <%= user_agent.platform %> # Macintosh
    # Mobile: <%= user_agent.mobile? %> # False
    # OS: <%= user_agent.os %> # OS X 10.8
    user_agent.mobile?
  end

  def h_menu_index_action(modelname)
    fname = "#{self.class.name}.#{__method__}"
    ret = ''
    ret += "<div id='menu_index_action' class='menu_toolbar'>"
    ret += "<table class='menu_toolbar'>"
    ret +=	'<tr>'
    #
    link = t("new_#{modelname}")
    url = { controller: get_controller_from_model_type(modelname), action: :new }
    linkto = eval "link_to('#{link}', #{url})"
    ret += "<td>#{linkto}</td>"
    #
    link = t('export_objects')
    url = { controller: get_controller_from_model_type(modelname), action: :export }
    linkto = eval "link_to('#{link}', #{url})"
    ret += "<td>#{linkto}</td>"
    #
    ret += h_menu_execute_submit(modelname).to_s
    help = show_help("help_#{modelname}s")
    ret << "<td id='separator_vertical'></td>"
    ret +=	"<td>#{help}</td>"
    ret +=	'</tr>'
    ret += '</table>'
    ret += '</div>'
    # LOG.debug(fname){"h_menu_index_action=#{ret}"}
    ret.html_safe unless ret.html_safe?
  end

  def h_menu_duplicate(object_plm)
    # new_dup_customer_path
    url = '{new_dup_object_plm.modelname}_path'
    link_to h_img(:duplicate), controller: object_plm.controller_name, action: :new_dup, id: object_plm.id
  end

  def h_menu_execute_submit(modelname)
    ret = ''
    ret << "<td id='separator_vertical'></td>"
    submit_copy = t('submit_copy')
    submit_destroy = t('submit_destroy')
    if logged_in? && Clipboard.can_clipboard?(modelname)
      ret << "<td>#{submit_tag(submit_copy)}</td>"
    end
    ret.html_safe unless ret.html_safe?
  end

  def h_menu_rails2(href, _help, title)
    bloc = ''
    # ne marche pas avec boostrap bloc<<"<a class='menu' onclick=\"return helpPopup('#{help}','#{href}');\" >#{title}</a>";
    bloc << "<a class='menu' id='#{title} name='#{title}' href='#{href}' >#{title}</a>"
    bloc.html_safe? unless ret.html_safe?
  end

  def h_menu(href, _help, title)
    link_to title, href, class: 'menu', id: title, name: title
  end
end
