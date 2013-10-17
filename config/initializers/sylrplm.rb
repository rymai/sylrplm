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

	#########################################
	# Properties
	#
	PLM_PROPERTIES						= "sylrplm_properties"
	#
	# repertoires des chargements
	#TODO not yet in property
	DIR_FIXTURES               = "#{Rails.root}/db/fixtures"
	#TODO not yet in property
	VOLUME_DIRECTORY_DEFAULT  = case OsFunctions.os
	when "linux"
		"/home/syl/trav/rubyonrails/sylrplm-data-#{Rails.env}"
	when "mac"
		"/Users/remy/Development/Ruby/Gems/sylvani/sylrplm/sylrplm_data_#{Rails.env}"
	when "windows"
		"C:\\sylrplm-data-#{Rails.env}"
	end


		# document de type directory (pour eviter par exemple d'y mettre des fichiers)
		TYPE_DOC_DIRECTORY        = 'directory'
# type de user: personne physique.
		TYPE_USER_PERSON          = 'person_'
		# type du projet affecte par defaut a un user lors de sa creation
		TYPE_PROJ_ACCOUNT         = '$PROJ_ACCOUNT'
		# valeurs des types d'acces a un  projet
		TYPEACCESS_PUBLIC         = 'public'
		TYPEACCESS_CONFIDENTIAL   = 'confidential'
		TYPEACCESS_SECRET         = 'secret'
		FOG_ACCESS_KEY            = "W2ft89uVn3DqX1qw1WQRKWmpzPZZKZDAV/j2j/0j"
		FOG_ACCESS_KEY_ID         = "AKIAIUTZHUXCXNUFDRHQ"

	#
	# no more used, use PlmServices.get_property("HELP_SUMMARY_LEVEL") for example
	# properties are now stored in Typesobject table and managed by PlmServices
	#
	if false
		###########################################
		#
		# plm objects names / nom de certains objets plm
		#
		# groupes
		GROUP_ADMINS              = 'admins'
		# Roles
		ROLE_ADMIN                = 'admin'
		ROLE_CONSULTANT           = 'consultant'
		ROLE_CREATOR              = 'creator'
		ROLE_VALIDER              = 'valider'
		ROLE_PROJECT_MANAGER      = 'project_manager'
		ROLE_ANALYST              = 'analyst'
		ROLE_DESIGNER             = 'designer'
		# User administrator
		USER_ADMIN                = 'admin'
		#
		# types value / valeurs des types
		#
		# n'importe quel object plm
		PLMTYPE_GENERIC           = 'any_plmtype'
		# n'importe quel type
		TYPE_GENERIC              = 'any_type'
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

		# type de l'image representative d'un document
		TYPE_DATAFILE_THUMBNAIL   = 'thumbnail'

		# valeurs de certains objets
		########TODO inutile ??? RELATION_GENERIC          = 'any_relation'
		#
		# domaine par defaut utilise lors de la creation d'objets
		DOMAIN_DEFAULT  					= 'user.'
		# doit on demander le domaine pour tous les users lors de la creation d'objets ?
		DOMAIN_FOR_ALL 					  = true
		#
		#
		########TODO inutile ??? MAIL_ADMIN                = "sylvere.coutable@laposte.net"
		FOG_ACCESS_KEY            = "W2ft89uVn3DqX1qw1WQRKWmpzPZZKZDAV/j2j/0j"
		FOG_ACCESS_KEY_ID         = "AKIAIUTZHUXCXNUFDRHQ"
		# environnement specifique a l'admin de l'application sylrplm
		# ordre des constituants de l'arbre
		TREE_ORDER                = ["forum", "document", "part", "project", "customer" ]
		TREE_UP_ORDER             = ["document", "part", "project", "customer" ]
		# regroupement des composants d'un objet dans l'explorer
		TREE_GROUP                = false
		# niveau maxi du sommaire de l'aide
		HELP_SUMMARY_LEVEL        = 3
		#########################################
		#
		# The default values ​​assigned to a user
		#
		# default theme (user.theme)
		THEME_DEFAULT             = "white"
		# default language (user.language)
		LOCAL_DEFAULT             = "fr"
		# volume name / nom du volume attribue par defaut au user (user.volume)
		VOLUME_NAME_DEFAULT       = "vollocal01"
		# number of items in index page (user.nb_items)
		NB_ITEMS_PER_PAGE         = 30
		########TODO inutile ??? TIME_ZONE_DEFAULT         = 1
		# user type: person
		TYPE_USER_DEFAULT         = TYPE_USER_NEW_ACCOUNT
		# role
		ROLE_USER_DEFAULT         = ROLE_CONSULTANT
		# Nom des projets attribués automatiquement a un nouvel utilisateur
		PROJECTS_ACCOUNT          = 'PROJECT-users,PROJET TABLE'
		# Nom des groupes attribués automatiquement a un nouvel utilisateur
		GROUPS_ACCOUNT        		= 'admins,consultants,SICM'

	end

end

