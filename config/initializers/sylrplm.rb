# 
#  sylrplm.rb
#  sylrplm
#  
#  Created by Sylvère on 2012-02-04.
#  Copyright 2012 Sylvère. All rights reserved.
# 
require 'classes/app_classes'
require 'os_functions'

module SYLRPLM
  #include Classes::AppClasses::LogFormatter
  LOCAL_DEFAULT             = "fr"
  NOTIFICATION_DEFAULT      = 1
  TIME_ZONE_DEFAULT         = 1
  THEME_DEFAULT             = "blackwhite"
  NB_ITEMS_PER_PAGE         = 30
  #
  # nom de certains objets plm
  #
  # n'importe quel object plm
  PLMTYPE_GENERIC           = 'any_plmtype'
  # groupes
  GROUP_ADMINS              = 'admins'
  GROUP_CONSULTANTS         = 'consultants'
  GROUP_CREATORS            = 'creators'
  GROUP_VALIDERS            = 'validers'
  # Roles
  ROLE_ADMIN                = 'admin'
  ROLE_CONSULTANT           = 'consultant'
  ROLE_CREATOR              = 'creator'
  ROLE_VALIDER              = 'valider'
  ROLE_PROJECT_MANAGER      = 'project_manager'
  ROLE_ANALYST              = 'analyst'
  ROLE_DESIGNER             = 'designer'
  # User administrateur
  USER_ADMIN                = 'admin'
  #
  # valeurs des types
  #
  # n'importe quel type
  TYPE_GENERIC              = 'any_type'
  # n'importe quelle relation
  TYPE_RELATION_GENERIC     = 'any_relation_type'
  # type de user: personne physique.
  TYPE_USER_PERSON          = 'person_'
  # type de user: user virtuel, pour batchs...
  TYPE_USER_VIRTUAL         = 'virtual_'
  # Type attribué a un nouvel utilisateur avant sa validation
  TYPE_USER_NEW_ACCOUNT     = '$NEW_ACCOUNT'
  # type du projet affecte par defaut a un user lors de sa creation
  TYPE_PROJ_ACCOUNT         = '$PROJ_ACCOUNT'
  # valeurs des types d'acces a un  projet
  TYPEACCESS_PUBLIC         = 'public'
  TYPEACCESS_CONFIDENTIAL   = 'confidential'
  TYPEACCESS_SECRET         = 'secret'
  # valeurs de certains objets
  RELATION_GENERIC          = 'any_relation'
  #
  # Prefixe du nom du projet attribué automatiquement a un nouvel utilisateur
  USER_PROJECT_IDENT        = 'PROJECT-'
  # repertoires des chargement initial, voir Controller
  DIR_FIXTURES               = "#{Rails.root}/db/fixtures"
  MAIL_ADMIN                = "sylvere.coutable@laposte.net"
  FOG_ACCESS_KEY            = "W2ft89uVn3DqX1qw1WQRKWmpzPZZKZDAV/j2j/0j"
  FOG_ACCESS_KEY_ID         = "AKIAIUTZHUXCXNUFDRHQ"
  # environnement specifique a l'admin de l'application sylrplm
  VOLUME_DIRECTORY_DEFAULT  = case OsFunctions.os
  when "linux"
    "/home/syl/trav/rubyonrails/sylrplm_data_#{Rails.env}"
  when "mac"
    "/Users/remy/Development/Ruby/Gems/sylvani/sylrplm/sylrplm_data_#{Rails.env}"
  when "windows"
    "C:\\sylrplm_data_#{Rails.env}"
  end
  # ordre des constituants de l'arbre
  TREE_ORDER                = ["forum", "document", "part", "project", "customer" ]
  TREE_UP_ORDER             = ["document", "part", "project", "customer" ]
  # regroupement des composants d'un objet 
  TREE_GROUP                = true
end

