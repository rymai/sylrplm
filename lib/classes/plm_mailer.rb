# frozen_string_literal: true

class PlmMailer < ActionMailer::Base
  def self.listUserMail(users, userExclude = nil)
    ret = []
    users.each do |user|
      if userExclude.nil? || userExclude.login != user.login
        ret << user.login + '<' + user.email + '>'
      end
    end
    puts 'PlmMailer.listUserMail:' + ret.inspect
    ret
  end

    # send a mail to new_user (to) from admin (from)
	def new_login(from, to, urlbase, sent_at = Time.now)
		bodyMail={}
        bodyMail["user"]=to
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#new_login',
        to: to.email,
        from:       from.email,
        sent_on:    sent_at,
        body: bodyMail)
	end

     def toValidate(object, from, urlbase, validers, sent_at = Time.now)
        bodyMail={}
        bodyMail["object"]=object
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#ToValidate',
        to: to.email,
        from:       from.email,
        sent_on:    sent_at,
        body: bodyMail)
    end


def validated(object, from, urlbase, validersMail, sent_at = Time.now)
        bodyMail={}
        bodyMail["object"]=to
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#docValidated',
        to: to.email,
        from:       from.email,
        sent_on:    sent_at,
        body: bodyMail)
    end

    def docToValidate(document, from, urlbase, validers, sent_at = Time.now)
        vbodyMail={}
        bodyMail["document"]=document
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#docToValidate',
        to: to.email,
        from:       from.email,
        sent_on:    sent_at,
        body: bodyMail)
    end

  def notify(object, from, to, sent_at = Time.now)
    @user = from
    bodyMail = {}
    bodyMail['user'] = to
    bodyMail['notifications'] = object
    bodyMail['theme'] = from.theme
    mail(subject:    'PLMMailer#create_notify',
         to: to.email,
         from:       from.email,
         sent_on:    sent_at,
         body: bodyMail)
  end

    def partToValidate(part, from, urlbase, validers, sent_at = Time.now)
        bodyMail={}
        bodyMail["part"]=part
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#partToValidate',
        recipients: asker,
        from:       from.email,
        cc:      validersMail,
        sent_on:    sent_at,
        body: bodyMail)
    end

     def partValidated(part, from, urlbase, asker, validersMail, sent_at = Time.now)
        bodyMail={}
        bodyMail["part"]=part
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#partValidated',
        recipients: asker,
        from:       from.email,
        cc:      validersMail,
        sent_on:    sent_at,
        body: bodyMail)
    end

    def contactSylrplm(object, from, to, urlbase, sent_at = Time.now)
        bodyMail={}
        bodyMail["user"]=to
        bodyMail["urlbase"]=urlbase
        mail(subject:    'PLMMailer#new_login',
        to: to.email,
        from:       from.email,
        sent_on:    sent_at,
        body: bodyMail)
    end

     def sendContact(from_email, to, subject, body, sent_at = Time.now)
        @user_to=to
        @from_email=from_email
        @body=body
        mail(subject:     "PLMMailer:Contact from #{from_email} : #{subject}",
        recipients: to,
        from:       from_email,
        to:      to.email,
        sent_on:    sent_at,
        body: body)
    end

  # rails4
  def docValidated(document, from, urlbase, asker, validersMail, sent_at = Time.now)
    @user = from
    @url = urlbase
    bodyMail = {}
    bodyMail['document'] = document
    bodyMail['urlbase'] = urlbase
    mail(subject:    'PLMMailer#docValidated',
         recipients: asker,
         from:       from.email,
         cc:      validersMail,
         sent_on:    sent_at,
         body: bodyMail)
  end


end
