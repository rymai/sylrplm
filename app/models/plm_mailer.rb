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

	def notify(object, from, to, sent_at = Time.now)
		subject    'PLMMailer#create_notify'
		recipients to.email
		from       from.email
		sent_on    sent_at
		body["user"] = to
		body["notifications"]=object
		body["theme"]=from.theme
		content_type "text/html"
	end

	def new_login(object, from, to, urlbase, sent_at = Time.now)
		subject    'PLMMailer#new_login'
		recipients to.email
		from     from.email
		cc         from.email
		sent_on    sent_at
		body["user"]=object
		body["urlbase"]=urlbase
		content_type "text/html"
	end

	def toValidate(object, from, urlbase, validers, sent_at = Time.now)
		subject    'PLMMailer#docToValidate'
		recipients validers
		from       from.email
		sent_on    sent_at
		body["object"]=object
		body["urlbase"]=urlbase
		content_type "text/html"
	end

	def validated(object, from, urlbase, validersMail, sent_at = Time.now)
		subject    'PLMMailer#docValidated'
		recipients object.owner.email
		from       from.email
		cc      validersMail
		sent_on    sent_at
		body["object"]=object
		body["urlbase"]=urlbase
		content_type "text/html"
	end

	def docToValidate(document, from, urlbase, validers, sent_at = Time.now)
		subject    'PLMMailer#docToValidate'
		recipients validers
		from       from.email
		sent_on    sent_at
		body["document"]=document
		body["urlbase"]=urlbase
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

	def partToValidate(part, from, urlbase, validers, sent_at = Time.now)
		subject    'PLMMailer#partToValidate'
		recipients validers
		from       from.email
		sent_on    sent_at
		body["part"]=part
		body["urlbase"]=urlbase
	end

	def partValidated(part, from, urlbase, asker, validersMail, sent_at = Time.now)
		subject    'PLMMailer#partValidated'
		recipients asker
		from       from.email
		cc      validersMail
		sent_on    sent_at
		body["part"]=part
		body["urlbase"]=urlbase
	end

end
