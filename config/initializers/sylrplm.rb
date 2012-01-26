require 'classes/app_classes'

module SYLRPLM
  #include Classes::AppClasses::LogFormatter
  LOCAL_DEFAULT             = "fr"
  NOTIFICATION_DEFAULT      = 1
  TIME_ZONE_DEFAULT         = 1
  THEME_DEFAULT             = "blackwhite"
  NB_ITEMS_PER_PAGE         = 30
  # attribut name de certains objets
  NAME_GENERIC              = '_generic_name'
  #
  # nom de certains objets plm
  #
  # n'importe quel object
  PLMTYPE_GENERIC           = '_generic_object'
  # groupes
  GROUP_ADMINS              = 'admins'
  GROUP_CONSULTANTS         = 'consultants'
  GROUP_CREATORS            = 'creators'
  GROUP_VALIDERS            = 'validers'
  # Roles
  ROLE_ADMIN                = 'admin'
  ROLE_CONSULTANT           = 'consultant'
  ROLE_CREATOR              = 'creator'
  ROLE_ANALYST              = 'analyst'
  ROLE_DESIGNER             = 'designer'
  ROLE_VALIDER              = 'valider'
  ROLE_PROJECT_MANAGER      = 'project_manager'
  # User administrateur
  USER_ADMIN                = 'admin'
  #
  # valeurs des types
  #
  # type de user: personne physique.
  TYPE_USER_PERSON          = 'person'
  # type de user: user virtuel, pour batchs...
  TYPE_USER_VIRTUAL         = 'virtual'
  # Type attribué a un nouvel utilisateur avant sa validation
  TYPE_USER_NEW_ACCOUNT     = '#NEW_ACCOUNT'
  # type du projet affecte par defaut a un user lors de sa creation
  TYPE_PROJ_ACCOUNT         = '#PROJ_ACCOUNT'
  # n'importe quel type
  TYPE_GENERIC              = '_generic_type'
  # valeurs des types d'acces a un  projet
  TYPEACCESS_PUBLIC         = 'public'
  TYPEACCESS_CONFIDENTIAL   = 'confidential'
  TYPEACCESS_SECRET         = 'secret'
  #
  # Prefixe du nom du projet attribué automatiquement a un nouvel utilisateur
  USER_PROJECT_IDENT        = 'PROJECT-'
  # chargement initial, voir Controller
  DIR_DOMAINS               = "#{Rails.root}/db/fixtures/domains/"
  DIR_ADMIN                 = "#{Rails.root}/db/fixtures/admin/"
  MAIL_ADMIN                = "sylvere.coutable@laposte.net"
  FOG_ACCESS_KEY            = "W2ft89uVn3DqX1qw1WQRKWmpzPZZKZDAV/j2j/0j"
  FOG_ACCESS_KEY_ID         = "AKIAIUTZHUXCXNUFDRHQ"
  # environneemnt specifique a l'admin de l'application sylrplm
  VOLUME_DIRECTORY_DEFAULT  = case OsFunctions.os
  when "linux"
    "/home/syl/trav/rubyonrails/sylrplm_data"
  when "mac"
    "/Users/remy/Development/Ruby/Gems/sylvani/sylrplm/sylrplm_data"
  when "windows"
    "C:\\sylrplm_data"
  end
end

#
# fichier de log specifique
#
logfile       = File.join(Rails.root, 'log', 'sylrplm.log')
LOG           = Logger.new(logfile, 'daily')
LOG.level     = Logger::DEBUG #DEBUG INFO WARN ERROR FATAL
LOG.formatter = Classes::AppClasses::LogFormatter.new  # Install custom formatter!
#@logger.datetime_format = "%Y-%m-%d %H:%M:%S"
LOG.info("sylrplm"){"Lancement SYLRPLM"}
LOG.info("sylrplm"){"logs dans: #{logfile}"}
LOG.progname="constantes"
LOG.info {"Constantes du module SYLRPLM:"}
SYLRPLM.constants.sort.each do |c|
  v = SYLRPLM.const_get(c)
  LOG.debug("sylrplm"){"#{c}\t\t= #{v}"}
end
LOG.info {"--------------------------------------------"}
