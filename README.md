# SylRPLM : Product Life Management

## Pré-requis

- RubyGems : https://rubygems.org/pages/download
- Ruby 1.9.3

## Mise en place

- Cloner le repository git hébergé sur GitHub : `$> git clone git://github.com/sylvani/sylrplm.git`
- Installation des gems : `$> cd sylrplm && bundle install`

- (FIXME) Environnement Windows
    - Ajouter le chemin de mysql/bin au PATH
    - Télécharger http://instantrails.rubyforge.org/svn/trunk/InstantRails-win/InstantRails/mysql/bin/libmySQL.dll
    et copier la dll dans le répertoire bin de Ruby

## Setup de développement

- Créer la DB et générer des données de base

  `$> alias be="bundle exec"`
  `$> be rake db:reset` (seulement si changement de modele)
  `$> be rake 'sylrplm:import_domain[db/custos/sicm,sicm.custo]'` (recharge le parametrage de base)
  `$> be rake 'sylrplm:import_domain[db/custos/sicm,sample.table]'` (recharge un exemple de projet)

- Créer le fichier `.env` qui contient les variables d'environnement utilisées par l'app:
  `$> echo "RACK_ENV=development" >>.env`

## Déploiement sur Heroku

- [Installer la Heroku Toolbelt](https://toolbelt.heroku.com).
- Pusher sur la git remote `production` (Heroku): `$> git push production`
- Lancer les migrations (si besoin): `$> heroku run rake db:migrate`
