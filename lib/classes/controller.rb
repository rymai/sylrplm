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
    fname = "#{self.class.name}.#{__method__}"
    controllers_and_methods = []

    Dir.glob(Rails.root.join('app/controllers', '**', '*_controller.rb')).each_with_index do |file, index|
      ###puts "Controller.get_controllers:"+controller
      controller = File.basename(file, '.rb').camelize
      controller_class = controller.safe_constantize
      next unless controller_class

      controller_class.instance_methods(false).sort.each do |smet|
        next if controller == 'ApplicationController'

        method = smet.to_s

        if controller != 'SessionsController' &&
           (
             %w[init_objects login logout].include?(method) ||
             method =~ /(_old|authorized)($|_obsolete$|_$)/
           )
          next
        end

        controllers_and_methods << Controller.new(index, controller, method)
      end
    end
    LOG.debug(fname) { "Number of controllers and methods=#{controllers_and_methods.count}" }

    controllers_and_methods
  end

  def self.route_exists?(controller, action)
    fname= "#{self.class.name}.#{__method__}"
    cont = "#{controller}_controller".camelize
    LOG.debug(fname){"Controller.route_exists? controller=#{controller} , cont=#{cont} , action=#{action})"}
    methods=eval("::#{cont}.new.methods")
    #LOG.debug(fname){"Controller.route_exists?:methods=#{methods}"}
    ret = methods.include? action.to_sym
    LOG.debug(fname){"Controller.route_exists?(#{cont}, #{action.to_sym})=#{ret}"}
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
      User.get_all.each do |auser|
        auser.volume=vol
        ##auser.password=auser.login
        auser.save
      #puts "Controller.update_admin="+auser.inspect
      end
    end
  end

  def self.get_types_by_features(only_admin=false)
    fname="Controller.#{__method__}"
    LOG.info(fname) { "only_admin=#{only_admin}"}
    ret={}
    # TODO temporary
    features = [:document, :part, :project, :customer]
    features_types = {}
    features.each do |feature|
      features_types[feature]=[]
      # TODO temporary
      plmtype = feature
      # types, including the generic one
      types = ::Typesobject.get_types(plmtype, false)
      LOG.debug(fname) {"types for #{feature}=#{types}l"}
      types.each do |type|
        if !only_admin || type.domain==::SYLRPLM::DOMAIN_ADMIN
          unless type.nil?
          features_types[feature] << type
          else
            LOG.error(fname) {"Error:  a type of #{feature} is nil"}
          end
        end
      end
      features_types[feature].sort! do |type1 , type2|
        mdl1 = type1.forobject+"s"
        mnu1=tr_def("mnu_#{mdl1}_#{type1.name}")
        mdl2 = type2.forobject+"s"
        mnu2=tr_def("mnu_#{mdl2}_#{type2.name}")
        compare=mnu1 <=> mnu2
        LOG.info(fname) { "compare:#{mnu1}<=>#{mnu2}=#{compare}"}
        compare
      end
      generic_type = Typesobject.generic(feature)
      divider=Typesobject.new ({:name=>"divider",:forobject=>feature})
      ret[feature]=[]
      ret[feature] << generic_type
      ret[feature] << divider
      features_types[feature].each do |menus|
        ret[feature] << menus
      end

    end
    LOG.debug(fname) {"ret=#{ret}"}
    ret
  end

  def self.tr_def(key)
    ::PlmServices.translate(key,:default=> "%#{key}%")
  end
end
