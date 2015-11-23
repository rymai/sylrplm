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
	fname="sylrplm.rb:"
	puts ">>>>#{fname}"
	#########################################
	# version
	SYLRPLM_VERSION					= "1.0.1"
	SYLRPLM_DATE						= "2014/09/20".to_date
	#
	# Type name for Properties
	PLM_PROPERTIES						= "sylrplm_properties"

	# max number of recent objects seen by user, each user can modify it
	MAX_RECENT_ACTION					= 30
	# name of the relation to store link about user recent action
	RELATION_RECENT_ACTION		= "RECENT_ACTION"
	# admin domain name to keep OOTB functionnalities
	DOMAIN_ADMIN							= "admin"
	#
	# repertoires des chargements
	#TODO not yet in property
	DIR_FIXTURES               = "#{Rails.root}/db/fixtures"
	# for local volumes
	VOLUME_DIRECTORY_DEFAULT  = case OsFunctions.os
	when "linux"
		"/home/syl/trav/rubyonrails/sylrplm-data"
	when "mac"
		"/Users/remy/Development/Ruby/Gems/sylvani/sylrplm/sylrplm_data"
	when "windows"
		"C:\\sylrplm-data"
	end
	# document de type directory (pour eviter par exemple d'y mettre des fichiers)
	TYPE_DOC_DIRECTORY        = "directory"

	#
	# no more used, use PlmServices.get_property("HELP_SUMMARY_LEVEL") for example
	# properties are now stored in Typesobject table and managed by PlmServices
	#

	###########################################
	#
	# plm objects names / nom de certains objets plm
	#
	# sites

	# groupes
	GROUP_ADMINS              = 'admins'
	GROUP_CONSULTANTS   = 'consultants'
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
	# type de l'image representative d'un document
	TYPE_DATAFILE_THUMBNAIL   = 'thumbnail'

	TYPEACCESS_PUBLIC         = 'public'
	TYPEACCESS_CONFIDENTIAL   = 'confidential'
	TYPEACCESS_SECRET         = 'secret'

	DOCUMENT_REVISE = "true"
	CUSTOMER_REVISE = "false"
	PART_REVISE = "true"
	PROJECT_REVISE = "false"

	THEME_DEFAULT="white"
	TREE_ORDER=["forum", "document", "part", "project", "customer"]
	TREE_UP_ORDER=["document", "part", "project", "customer"]
	TREE_GROUP=false
	TREE_RELATION_STOP=["FROM_REVISION", "FROM_DUPLICATE"]

	NB_ITEMS_PER_PAGE=30

	SITE_CENTRAL                               =  "limours"

	FOG_ACCESS_KEY="/3TLl+gwrWQj/2HGfKWj5ntc3UIQNwjPCGkqDWHG"
	FOG_ACCESS_KEY_ID="AKIAIUD54MZOYMFWXYEQ"

	if false
		# valeurs des types d'acces a un  projet

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

	end

	puts "<<<<#{fname}"
end

