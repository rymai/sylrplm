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
  
  def toValidate(object, fromMail, urlbase, validers, sent_at = Time.now)
    subject    'PLMMailer#docToValidate'
    recipients validers
    from       fromMail
    sent_on    sent_at
    body["object"]=object
    body["urlbase"]=urlbase
  end
  
  def validated(object, fromMail, urlbase, asker, validersMail, sent_at = Time.now)
    subject    'PLMMailer#docValidated'
    recipients asker
    from       fromMail
    cc      validersMail
    sent_on    sent_at 
    body["object"]=object
    body["urlbase"]=urlbase
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
