# Application SylRPLM : Product Life Management

* Pré-requis
  - RubyGems : https://rubygems.org/pages/download
  - Ruby >= 1.9.2

* Mise en place
  - Cloner le repository git hébergé sur GitHub :

        $> git clone git://github.com/sylvani/sylrplm.git

  ou

  - Télécharger le zip (https://github.com/sylvani/sylrplm/zipball/master) puis le décompresser :

        $> unzip sylrplm.zip -d sylrplm

  - Se placer dans la racine de l'application

        $> cd sylrplm

- Installation des gems

        $> bundle install

- Environnement windows
  - Ajouter le chemin de mysql/bin au PATH
  - Télécharger http://instantrails.rubyforge.org/svn/trunk/InstantRails-win/InstantRails/mysql/bin/libmySQL.dll
    et copier la dll dans le répertoire bin de Ruby

- Installation de l'application en developement

  - Créer et charger le schéma de la base de données

        $> alias be="bundle exec"
        # $> be rake db:drop && be rake db:create && be rake db:migrate && be rake db:populate
        $> rake db:reset # seulement si changement de modele
        $> rake sylrplm:import_domain[db/custos/sicm,sicm.custo] # recharge le parametrage de base
        $> rake sylrplm:import_domain[db/custos/sicm,sample.table] # recharge un exemple de projet

- Installation de l'application sur Heroku

  - Charger le schéma de la base de données (chaque app est créée avec une base)

        $> bundle exec heroku rake db:migrate