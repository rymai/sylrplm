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

	def notify_rails2(object, from, to, sent_at = Time.now)
		subject    'PLMMailer#create_notify'
		recipients to.email
		from       from.email
		sent_on    sent_at
		body["user"] = to
		body["notifications"]=object
		body["theme"]=from.theme
		content_type "text/html"
	end

	def notify(object, from, to, sent_at = Time.now)
		@user = from
		bodyMail={}
		bodyMail["user"]=to
		bodyMail["notifications"]=object
		bodyMail["theme"]=from.theme
		mail(subject:    'PLMMailer#create_notify',
		to: to.email,
		from:       from.email,
		sent_on:    sent_at,
		body: bodyMail)
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

    def toValidate_rails2 (object, from, urlbase, validers, sent_at = Time.now)
        subject    'PLMMailer#docToValidate'
        recipients validers
        from       from.email
        sent_on    sent_at
        body["object"]=object
        body["urlbase"]=urlbase
        content_type "text/html"
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

	def validatedRails2(object, from, urlbase, validersMail, sent_at = Time.now)
        subject    'PLMMailer#docValidated'
        recipients object.owner.email
        from       from.email
        cc      validersMail
        sent_on    sent_at
        body["object"]=object
        body["urlbase"]=urlbase
        content_type "text/html"
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

    def docToValidateRails2(document, from, urlbase, validers, sent_at = Time.now)
        subject    'PLMMailer#docToValidate'
        recipients validers
        from       from.email
        sent_on    sent_at
        body["document"]=document
        body["urlbase"]=urlbase
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

	def docValidated(document, from, urlbase, asker, validersMail, sent_at = Time.now)
		subject    'PLMMailer#docValidated'
		recipients asker
		from       from.email
		cc      validersMail
		sent_on    sent_at
		body["document"]=document
		body["urlbase"]=urlbase
	end

	#rails4
	def docValidated(document, from, urlbase, asker, validersMail, sent_at = Time.now)
		@user = from
		@url  = urlbase
		bodyMail={}
		bodyMail["document"]=document
		bodyMail["urlbase"]=urlbase
		mail(subject:    'PLMMailer#docValidated',
		recipients: asker,
		from:       from.email,
		cc:      validersMail,
		sent_on:    sent_at,
		body: bodyMail)
	end

    def partToValidateRails2(part, from, urlbase, validers, sent_at = Time.now)
        subject    'PLMMailer#partToValidate'
        recipients validers
        from       from.email
        sent_on    sent_at
        body["part"]=part
        body["urlbase"]=urlbase
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

    def partValidatedRails2(part, from, urlbase, asker, validersMail, sent_at = Time.now)
        subject    'PLMMailer#partValidated'
        recipients asker
        from       from.email
        cc      validersMail
        sent_on    sent_at
        body["part"]=part
        body["urlbase"]=urlbase
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

end
