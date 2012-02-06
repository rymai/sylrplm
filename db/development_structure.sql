CREATE TABLE `accesses` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `roles` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `controller` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `action` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_accesses_on_roles` (`roles`),
  KEY `index_accesses_on_controller` (`controller`),
  KEY `index_accesses_on_action` (`action`)
) ENGINE=InnoDB AUTO_INCREMENT=176 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `ar_workitems` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fei` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wfid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `expid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wfname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wfrevision` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `participant_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `store_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wi_fields` text COLLATE utf8_unicode_ci,
  `activity` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `keywords` text COLLATE utf8_unicode_ci,
  `dispatch_time` datetime DEFAULT NULL,
  `last_modified` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_ar_workitems_on_fei` (`fei`),
  KEY `index_ar_workitems_on_wfid` (`wfid`),
  KEY `index_ar_workitems_on_expid` (`expid`),
  KEY `index_ar_workitems_on_wfname` (`wfname`),
  KEY `index_ar_workitems_on_wfrevision` (`wfrevision`),
  KEY `index_ar_workitems_on_participant_name` (`participant_name`),
  KEY `index_ar_workitems_on_store_name` (`store_name`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `checks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `in_reason` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `in_date` date DEFAULT NULL,
  `out_reason` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `out_date` date DEFAULT NULL,
  `local_dir` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `in_user_id` int(11) DEFAULT NULL,
  `out_user_id` int(11) DEFAULT NULL,
  `in_group_id` int(11) DEFAULT NULL,
  `out_group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_checks_on_object_and_object_id` (`object`,`object_id`),
  KEY `index_checks_on_in_user_id` (`in_user_id`),
  KEY `index_checks_on_out_user_id` (`out_user_id`),
  KEY `index_checks_on_in_group_id` (`in_group_id`),
  KEY `index_checks_on_out_group_id` (`out_group_id`),
  KEY `index_checks_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `customers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `statusobject_id` int(11) DEFAULT NULL,
  `ident` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `designation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_customers_on_ident` (`ident`),
  KEY `index_customers_on_owner_id` (`owner_id`),
  KEY `index_customers_on_statusobject_id` (`statusobject_id`),
  KEY `index_customers_on_typesobject_id` (`typesobject_id`),
  KEY `index_customers_on_group_id` (`group_id`),
  KEY `index_customers_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `datafiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `document_id` int(11) DEFAULT NULL,
  `volume_id` int(11) DEFAULT NULL,
  `revision` int(11) DEFAULT NULL,
  `ident` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `filename` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `content_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_datafiles_on_document_id` (`document_id`),
  KEY `index_datafiles_on_typesobject_id` (`typesobject_id`),
  KEY `index_datafiles_on_volume_id` (`volume_id`),
  KEY `index_datafiles_on_group_id` (`group_id`),
  KEY `index_datafiles_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `definitions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `uri` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `launch_fields` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_definitions_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `statusobject_id` int(11) DEFAULT NULL,
  `ident` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `revision` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `designation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_documents_on_ident` (`ident`),
  KEY `index_documents_on_owner_id` (`owner_id`),
  KEY `index_documents_on_statusobject_id` (`statusobject_id`),
  KEY `index_documents_on_typesobject_id` (`typesobject_id`),
  KEY `index_documents_on_group_id` (`group_id`),
  KEY `index_documents_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `expressions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `fei` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `wfid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `expid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `exp_class` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `svalue` text COLLATE utf8_unicode_ci NOT NULL,
  `text` text COLLATE utf8_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `index_expressions_on_exp_class` (`exp_class`),
  KEY `index_expressions_on_expid` (`expid`),
  KEY `index_expressions_on_fei` (`fei`),
  KEY `index_expressions_on_wfid` (`wfid`)
) ENGINE=InnoDB AUTO_INCREMENT=112 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `forum_items` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `forum_id` int(11) DEFAULT NULL,
  `parent_id` int(11) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `message` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_forum_items_on_forum_id` (`forum_id`),
  KEY `index_forum_items_on_owner_id` (`owner_id`),
  KEY `index_forum_items_on_parent_id` (`parent_id`),
  KEY `index_forum_items_on_group_id` (`group_id`),
  KEY `index_forum_items_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `forums` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `statusobject_id` int(11) DEFAULT NULL,
  `subject` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_forums_on_owner_id` (`owner_id`),
  KEY `index_forums_on_statusobject_id` (`statusobject_id`),
  KEY `index_forums_on_typesobject_id` (`typesobject_id`),
  KEY `index_forums_on_group_id` (`group_id`),
  KEY `index_forums_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `group_definitions` (
  `group_id` int(11) DEFAULT NULL,
  `definition_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  UNIQUE KEY `index_group_definitions_on_group_id_and_definition_id` (`group_id`,`definition_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `groups` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `father_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_groups_on_name` (`name`),
  UNIQUE KEY `index_groups_father_id` (`father_id`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `source` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `event` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `wfid` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wfname` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `wfrevision` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `fei` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `participant` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `message` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `tree` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_history_on_created_at` (`created_at`),
  KEY `index_history_on_event` (`event`),
  KEY `index_history_on_participant` (`participant`),
  KEY `index_history_on_source` (`source`),
  KEY `index_history_on_wfid` (`wfid`),
  KEY `index_history_on_wfname` (`wfname`),
  KEY `index_history_on_wfrevision` (`wfrevision`)
) ENGINE=InnoDB AUTO_INCREMENT=403 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `links` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `father_plmtype` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `child_plmtype` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `father_id` int(11) DEFAULT NULL,
  `child_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `father_type_id` int(11) DEFAULT NULL,
  `child_type_id` int(11) DEFAULT NULL,
  `relation_id` int(11) DEFAULT NULL,
  `owner_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_links_on_child_type_and_child_id` (`child_plmtype`,`child_id`),
  KEY `index_links_on_father_type_and_father_id` (`father_plmtype`,`father_id`),
  KEY `index_links_on_father_type_id` (`father_type_id`),
  KEY `index_links_on_child_type_id` (`child_type_id`),
  KEY `index_links_on_relation_id` (`relation_id`),
  KEY `index_links_on_owner_id` (`owner_id`),
  KEY `index_links_on_group_id` (`group_id`),
  KEY `index_links_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `notifications` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object_type` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `object_id` int(11) DEFAULT NULL,
  `responsible_id` int(11) DEFAULT NULL,
  `event_type` text COLLATE utf8_unicode_ci,
  `event_date` date DEFAULT NULL,
  `notify_date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_notifications_on_object_type_and_object_id` (`object_type`,`object_id`),
  KEY `index_notifications_on_responsible_id` (`responsible_id`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `parts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `statusobject_id` int(11) DEFAULT NULL,
  `ident` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `revision` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `designation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `projowner_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_parts_on_ident` (`ident`),
  KEY `index_parts_on_owner_id` (`owner_id`),
  KEY `index_parts_on_statusobject_id` (`statusobject_id`),
  KEY `index_parts_on_typesobject_id` (`typesobject_id`),
  KEY `index_parts_on_group_id` (`group_id`),
  KEY `index_parts_on_projowner_id` (`projowner_id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `process_errors` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `wfid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `expid` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `svalue` text COLLATE utf8_unicode_ci NOT NULL,
  `created_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_process_errors_on_created_at` (`created_at`),
  KEY `index_process_errors_on_expid` (`expid`),
  KEY `index_process_errors_on_wfid` (`wfid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `projects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_id` int(11) DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `statusobject_id` int(11) DEFAULT NULL,
  `ident` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `designation` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `date` date DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `typeaccess_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_projects_on_ident` (`ident`),
  KEY `index_projects_on_owner_id` (`owner_id`),
  KEY `index_projects_on_statusobject_id` (`statusobject_id`),
  KEY `index_projects_on_typesobject_id` (`typesobject_id`),
  KEY `index_projects_on_typeaccess_id` (`typeaccess_id`),
  KEY `index_projects_on_group_id` (`group_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `projects_users` (
  `project_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  UNIQUE KEY `index_projects_users_on_user_id_and_project_id` (`user_id`,`project_id`),
  UNIQUE KEY `index_projects_users_on_project_id_and_user_id` (`project_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `questions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `question` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `answer` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `position` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `asker_id` int(11) DEFAULT NULL,
  `responder_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_questions_on_asker_id` (`asker_id`),
  KEY `index_questions_on_responder_id` (`responder_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `relations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `type_id` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `father_plmtype` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `child_plmtype` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `father_type_id` int(11) DEFAULT NULL,
  `child_type_id` int(11) DEFAULT NULL,
  `cardin_occur_min` int(11) DEFAULT NULL,
  `cardin_occur_max` int(11) DEFAULT NULL,
  `cardin_use_min` int(11) DEFAULT NULL,
  `cardin_use_max` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_relations_on_name` (`name`),
  KEY `index_relations_on_type_id` (`type_id`),
  KEY `index_relations_on_father_plmtype_and_father_type_id` (`father_plmtype`,`father_type_id`),
  KEY `index_relations_on_child_plmtype_and_child_type_id` (`child_plmtype`,`child_type_id`)
) ENGINE=InnoDB AUTO_INCREMENT=117 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `roles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `father_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_roles_on_father_id` (`father_id`)
) ENGINE=InnoDB AUTO_INCREMENT=105 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `roles_users` (
  `role_id` int(11) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  UNIQUE KEY `index_roles_users_on_role_id_and_user_id` (`role_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `schema_migrations` (
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  UNIQUE KEY `unique_schema_migrations` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sequences` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `value` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `min` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `max` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `utility` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `modify` tinyint(1) DEFAULT NULL,
  `sequence` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_sequences_on_utility` (`utility`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `data` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `index_sessions_on_session_id` (`session_id`),
  KEY `index_sessions_on_updated_at` (`updated_at`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `statusobjects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `rank` int(11) DEFAULT NULL,
  `promote_id` int(11) DEFAULT NULL,
  `demote_id` int(11) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_statusobjects_on_object_and_rank_and_name` (`object`,`rank`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `typesobjects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `object` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_typesobjects_on_object_and_name` (`object`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=172 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `user_groups` (
  `user_id` int(11) NOT NULL,
  `group_id` int(11) NOT NULL,
  UNIQUE KEY `index_user_groups_on_user_id_and_group_id` (`user_id`,`group_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `login` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `language` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `time_zone` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `theme` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `hashed_password` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `salt` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `role_id` int(11) DEFAULT NULL,
  `volume_id` int(11) DEFAULT NULL,
  `nb_items` int(11) DEFAULT NULL,
  `notification` int(11) DEFAULT NULL,
  `show_mail` tinyint(1) DEFAULT NULL,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `typesobject_id` int(11) DEFAULT NULL,
  `group_id` int(11) DEFAULT NULL,
  `project_id` int(11) DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_users_on_login` (`login`),
  KEY `index_users_on_role_id` (`role_id`),
  KEY `index_users_on_volume_id` (`volume_id`),
  KEY `index_users_on_typesobject_id` (`typesobject_id`),
  KEY `index_users_on_group_id` (`group_id`),
  KEY `index_users_on_project_id` (`project_id`)
) ENGINE=InnoDB AUTO_INCREMENT=108 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

CREATE TABLE `volumes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `directory` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `protocol` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8_unicode_ci,
  `created_at` datetime DEFAULT NULL,
  `updated_at` datetime DEFAULT NULL,
  `internal` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `index_volumes_on_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;

INSERT INTO schema_migrations (version) VALUES ('200910131418');

INSERT INTO schema_migrations (version) VALUES ('200910131419');

INSERT INTO schema_migrations (version) VALUES ('200910131420');

INSERT INTO schema_migrations (version) VALUES ('200910131421');

INSERT INTO schema_migrations (version) VALUES ('200910131612');

INSERT INTO schema_migrations (version) VALUES ('200910201808');

INSERT INTO schema_migrations (version) VALUES ('200910261544');

INSERT INTO schema_migrations (version) VALUES ('200910281829');

INSERT INTO schema_migrations (version) VALUES ('200911071449');

INSERT INTO schema_migrations (version) VALUES ('200912050919');

INSERT INTO schema_migrations (version) VALUES ('200912050952');

INSERT INTO schema_migrations (version) VALUES ('200912111622');

INSERT INTO schema_migrations (version) VALUES ('201001171028');

INSERT INTO schema_migrations (version) VALUES ('201002281204');

INSERT INTO schema_migrations (version) VALUES ('201010171706');

INSERT INTO schema_migrations (version) VALUES ('201011132051');

INSERT INTO schema_migrations (version) VALUES ('201103040100');

INSERT INTO schema_migrations (version) VALUES ('201103040200');

INSERT INTO schema_migrations (version) VALUES ('201103040700');

INSERT INTO schema_migrations (version) VALUES ('201106231854');

INSERT INTO schema_migrations (version) VALUES ('201107230100');

INSERT INTO schema_migrations (version) VALUES ('20110813170430');

INSERT INTO schema_migrations (version) VALUES ('20110920222430');