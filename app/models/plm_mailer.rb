class PlmMailer < ActionMailer::Base
  def self.listUserMail(users, userExclude=nil)
    ret=[]
    users.each do |user|
      if(userExclude==nil || userExclude.login!=user.login)
        ret << user.login+"<"+user.email+">"
      end
    end
    puts "PlmMailer.listUserMail:"+ret.inspect
    ret
  end

  def self.could_send(user)
    email_ok=true
    askUserMail=user.email
    puts "plm_mailer.could_send:"+askUserMail.to_s+"|"
    if askUserMail.blank?
      puts "plm_mailer.could_send:pas de mail"
      email_ok=false
    end
    email_ok
  end

  def notify(object, fromMail, to, sent_at = Time.now)
    subject    'PLMMailer#create_notify'
    recipients to.email
    from       fromMail
    sent_on    sent_at
    body["object"]=object
    content_type "text/html"
  end

  def toValidate(object, fromMail, urlbase, validers, sent_at = Time.now)
    subject    'PLMMailer#docToValidate'
    recipients validers
    from       fromMail
    sent_on    sent_at
    body["object"]=object
    body["urlbase"]=urlbase
    content_type "text/html"
  end

  def validated(object, fromMail, urlbase, validersMail, sent_at = Time.now)
    subject    'PLMMailer#docValidated'
    recipients object.owner.email
    from       fromMail
    cc      validersMail
    sent_on    sent_at
    body["object"]=object
    body["urlbase"]=urlbase
    content_type "text/html"
  end

  def docToValidate(document, fromMail, urlbase, validers, sent_at = Time.now)
    subject    'PLMMailer#docToValidate'
    recipients validers
    from       fromMail
    sent_on    sent_at
    body["document"]=document
    body["urlbase"]=urlbase
  end

  def docValidated(document, fromMail, urlbase, asker, validersMail, sent_at = Time.now)
    subject    'PLMMailer#docValidated'
    recipients asker
    from       fromMail
    cc      validersMail
    sent_on    sent_at
    body["document"]=document
    body["urlbase"]=urlbase
  end

  def partToValidate(part, fromMail, urlbase, validers, sent_at = Time.now)
    subject    'PLMMailer#partToValidate'
    recipients validers
    from       fromMail
    sent_on    sent_at
    body["part"]=part
    body["urlbase"]=urlbase
  end

  def partValidated(part, fromMail, urlbase, asker, validersMail, sent_at = Time.now)
    subject    'PLMMailer#partValidated'
    recipients asker
    from       fromMail
    cc      validersMail
    sent_on    sent_at
    body["part"]=part
    body["urlbase"]=urlbase
  end

end
