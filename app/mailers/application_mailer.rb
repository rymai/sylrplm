class ApplicationMailer < ActiveRecord::Observer
  default from: "sylvere.coutable@laposte.net"
  layout 'mailer'
  #content_type "text/html"
end
