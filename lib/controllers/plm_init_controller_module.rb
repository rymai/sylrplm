require 'active_record/fixtures'
module Controllers::PlmInitControllerModule
 
private
 
  def check_init
    if User.count == 0
      puts 'application_controller.check_init:base vide'
      flash[:notice]=t(:ctrl_init_to_do)
      respond_to do |format|
        format.html{redirect_to_main} 
      end
    end
  end
  
  #appelle par main_controller.init_objects
  def create_domain(domain)
    puts "plm_init_controller.create_domain:"+domain
    dirname=SYLRPLM::DIR_DOMAINS+domain+'/*.yml'
    puts "plm_init_controller.create_domain:"+dirname
    Dir.glob(dirname).each do |file|
      dirfile=SYLRPLM::DIR_DOMAINS+domain
      puts "plm_init_controller.create_domain:dirfile="+dirfile+" file="+File.basename(file, '.*')
      Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
    end
  end
  
  #appelle par main_controller.init_objects
  def create_admin
    puts "plm_init_controller.create_admin:"
    dirname=SYLRPLM::DIR_ADMIN+'*.yml'
    puts "plm_init_controller.create_admin:"+dirname
    Dir.glob(dirname).each do |file|
      dirfile=SYLRPLM::DIR_ADMIN
      puts "plm_init_controller.create_admin:dirfile="+dirfile+" file="+File.basename(file, '.*')
      Fixtures.create_fixtures(dirfile, File.basename(file, '.*'))
    end
  end
  
  #renvoie la liste des domaines pour le chargement initial
  #appelle par main_controller.init_objects
  def get_domains
    dirname=SYLRPLM::DIR_DOMAINS+'*'
    ret=""
    Dir.glob(dirname).each do |dir|
      ret<<"<option>"<<File.basename(dir, '.*')<<"</option>"
    end
    #puts "plm_init_controller.get_domains:"+dirname+"="+ret
    ret
  end
  
  #appelle par main_controller.init_objects
  #maj le volume de depart id=1 defini dans le fichier db/fixtures/volume.yml et cree par create_domain 
  def update_admin(dir)
    puts "plm_init_controller.update_first_volume:dir="+dir
    vol=Volume.find_first
    puts "plm_init_controller.update_first_volume:volume="+vol.inspect
    vol.update_attributes(:directory=>dir) unless vol.nil?
    User.find_all.each do |auser|
      auser.volume=vol
      auser.password=auser.login
      auser.save
      puts "plm_init_controller.update_first_volume:user="+auser.inspect
    end
  end
 
end