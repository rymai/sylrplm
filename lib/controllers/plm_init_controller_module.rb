require 'active_record/fixtures'
module Controllers::PlmInitControllerModule
 
  def check_init_objects
    ret =""
    
    #pour debug: forcer la reconstruction des access
    ya_acces=Access.count
    if ya_acces == 0
      ret +="Creation access<br>"
      st=Access.init
      st=true
      if st
        ret +="Acces  crees<br>"
      else
        ret +="ERREUR:Acces non crees completement<br>"
      end
    end
    puts 'main_controller.index:ya_acces='+ya_acces.to_s+":"+ret
    ret=""
    @types_document=Typesobject.find_for('document')
    if @types_document.size==0
      ret +="Pas de types de documents<br>"
    end
    @types_part=Typesobject.find_for('part')
    if @types_part.size==0
      ret +="Pas de types d articles<br>"
    end
    @types_project=Typesobject.find_for('project')
    if @types_project.size==0
      ret +="Pas de types de projets<br>"
    end
    @types_customer=Typesobject.find_for('customer')
    if @types_customer.size==0
      ret +="Pas de types de clients<br>"
    end
    @types_forum=Typesobject.find_for('forum')
    if @types_forum.size==0
      ret +="Pas de types de forums<br>"
    end
    
    @status_document= Statusobject.find_for("document")
    if @status_document.size==0
      ret +="Pas de statuts de documents<br>"
    end
    @status_part= Statusobject.find_for("part")
    if @status_part.size==0
      ret +="Pas de statuts d articles<br>"
    end
    @status_project= Statusobject.find_for("project")
    if @status_project.size==0
      ret +="Pas de statuts de projets<br>"
    end
    @status_customer= Statusobject.find_for("customer")
    if @status_customer.size==0
      ret +="Pas de statuts de clients<br>"
    end
    @status_forum= Statusobject.find_for("forum")
    if @status_forum.size==0
      ret +="Pas de statuts de forums<br>"
    end
    ret
  end
  
  def check_init
    ret=check_init_objects
    if ret != ""
      puts 'application_controller.check_init:message='+ret
      flash[:notice]=t(:ctrl_init_to_do)
      respond_to do |format|
        format.html{redirect_to :controller=>"main" , :action => "init_objects"} # init.html.erb
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
    puts "plm_init_controller.get_domains:"+dirname+"="+ret
    ret
  end
  
  #appelle par main_controller.init_objects
  #maj le volume de depart id=1 defini dans le fichier db/fixtures/volume.yml et cree par create_domain 
  def update_admin(dir)
    puts "plm_init_controller.update_first_volume:dir="+dir
    vol=Volume.find_first
    puts "plm_init_controller.update_first_volume:volume="+vol.inspect
    vol.update_attributes(:directory=>dir)
    User.find_all.each do |auser|
      auser.volume=vol
      auser.password=auser.login
      auser.save
      puts "plm_init_controller.update_first_volume:user="+auser.inspect
    end
  end
  
  
end