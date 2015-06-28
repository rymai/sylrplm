#require 'active_record/fixtures'
#require 'populate'
class Controller
	attr_accessor :id, :name, :method
	def initialize(i_id,i_name,i_method)
		@id=i_id
		@name=i_name
		@method=i_method
	end

	def name_method
		ret=@name+"."+@method
		ret
	end

	def self.get_controllers_and_methods
		fname= "#{self.class.name}.#{__method__}"
		ret=[]
		i=0
		controllers = Dir.new("#{RAILS_ROOT}/app/controllers").entries
		controllers.each do |controller|
			if controller =~ /_controller.rb/
				###puts "Controller.get_controllers:"+controller
				cont = controller.camelize.gsub(".rb","")
				#- Object.methods -
				#ApplicationController.methods -
				#ApplicationController.new.methods
				(eval("#{cont}.new.methods") -
				ApplicationController.new.methods).sort.each {|smet|
					LOG.debug (fname){"controller=#{cont} method=#{smet}"}
					met = smet.to_s
					if(met!='init_objects' && met!='login' && met!='logout' && met.index('_old')==nil && !met.end_with?('_') && met.index('_obsolete')==nil && met.index('_essai')==nil && met.index('authorized')==nil)
						ret<< Controller.new(i,cont,met)
					elsif (cont=="SessionsController")
						ret<< Controller.new(i,cont,met)
					end
					i=i+1;
				}
			end
		end
		puts
		ret
	end

	def self.route_exists?(controller, action)
		cont = "#{controller}_controller".camelize
		#puts "Controller.route_exists?(#{cont}, #{action})"
		methods=eval("::#{cont}.new.methods")
		#puts "Controller.route_exists?:methods=#{methods}"
		ret = methods.include? action.to_sym
		#puts "Controller.route_exists?(#{cont}, #{action.to_sym})=#{ret}"
		ret
	end

	def self.init_db(params)
		create_admin
		create_domain(params[:domain])
		update_admin(params[:directory])
	###st=Populate.access
	end

	#appelle par main_controller.init_objects
	def self.create_admin
		puts "Controller.create_admin:"
		dirname="#{PlmServices.get_property(:DIR_FIXTURES)}/admin/*.yml"
		puts "Controller.create_admin:"+dirname
		Dir.glob(dirname).each do |file|
			dirfile="#{PlmServices.get_property(:DIR_FIXTURES)}/admin"
			puts "Controller.create_admin:dirfile="+dirfile+" file="+File.basename(file, '.*')
			Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
		end
	end

	def self.create_domain(domain)
		puts "Controller.create_domain:"+domain
		dirname="#{PlmServices.get_property(:DIR_FIXTURES)}/domains/#{domain}/*.yml"
		puts "Controller.create_domain:"+dirname
		Dir.glob(dirname).each do |file|
			dirfile = "#{PlmServices.get_property(:DIR_FIXTURES)}/domains/#{domain}"
			puts "Controller.create_domain:dirfile="+dirfile+" file="+File.basename(file, '.*')
			Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
		end

	end

	#renvoie la liste des domaines pour le chargement initial
	#appelle par main_controller.init_objects
	def self.get_domains
		dirname="#{PlmServices.get_property(:DIR_FIXTURES)}/domains/*"
		ret=""
		Dir.glob(dirname).each do |dir|
			ret<<"<option>"<<File.basename(dir, '.*')<<"</option>"
		end
		#puts "plm_init_controller.get_domains:"+dirname+"="+ret
		ret
	end

	#appelle par main_controller.init_objects
	#maj le volume de depart id=1 defini dans le fichier db/fixtures/volume.yml et cree par create_domain
	def self.update_admin(dir)
		#puts "Controller.update_admin="+dir.to_s
		vol=Volume.find_first
		unless vol.nil?
			#vol.update_attributes(:directory=>dir) unless vol.nil?
			vol.set_directory
			puts "Controller.update_admin="+vol.name+" protocol="+vol.protocol+" dir="+vol.directory.to_s
			vol.save
			User.find_all.each do |auser|
				auser.volume=vol
				##auser.password=auser.login
				auser.save
			#puts "Controller.update_admin="+auser.inspect
			end
		end
	end

	def self.get_types_by_features(only_admin=false)
		fname="Controller.#{__method__}"
		LOG.info (fname) { "only_admin=#{only_admin}"}
		# TODO temporary
		features = [:document, :part, :project, :customer]
		features_types = {}

		features.each do |feature|
		# TODO temporary
			plmtype = feature
			# types, including the generic one
			types = ::Typesobject.get_types(plmtype, false)
			features_types[feature]=[]
			types.each do |type|
				if !only_admin || type.domain==::SYLRPLM::DOMAIN_ADMIN
				features_types[feature] << type
				end
			end
			LOG.info (fname) { "avant sort:#{features_types[feature]}"}
			features_types[feature].sort! do |type1 , type2|
				mdl1 = type1.forobject+"s"
				mnu1=tr_def("mnu_#{mdl1}_#{type1.name}")
				mdl2 = type2.forobject+"s"
				mnu2=tr_def("mnu_#{mdl2}_#{type2.name}")
				compare=mnu1 <=> mnu2
				LOG.info (fname) { "compare:#{mnu1}<=>#{mnu2}=#{compare}"}
				compare
			end
			LOG.info (fname) { "apres sort:"}
			features_types[feature].each { |typ| LOG.info (fname) { "type for #{feature} = #{typ.name}" } }
			generic_type = Typesobject.generic(feature)
			LOG.info (fname) { "generic_type for '#{feature}' = '#{generic_type.inspect}'"  }
			features_types[feature] << generic_type

		end
		##LOG.debug (fname) {"ret=#{features_types}"}
		features_types
	end

	def self.tr_def(key)
		::PlmServices.translate(key,:default=> "%#{key}%")
	end
end

