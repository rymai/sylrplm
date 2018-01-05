# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: 'sylvere.coutable@laposte.net'
  layout 'mailer'
  # content_type "text/html"
end
