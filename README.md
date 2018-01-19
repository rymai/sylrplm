# SylRPLM : Product Life Management

[![Code Climate](https://codeclimate.com/github/sylvani/sylrplm.png)](https://codeclimate.com/github/sylvani/sylrplm)

## Pré-requis

- RubyGems : https://rubygems.org/pages/download
- Ruby 2.3.6
- sgbd PostgreSQL 9.6 (defaut)

## Mise en place

- Cloner le repository git hébergé sur GitHub : `git clone git://github.com/sylvani/sylrplm.git`
- Installer les gems : `cd sylrplm && bundle install`

## Setup de développement

- Créer la DB et générer des données de base:
  ```
  # Seulement si changement de modele
  bin/rake db:reset

  # Recharger les données indispensables
  bin/rake 'sylrplm:import_domain[db/custos/sicm,sicm.custo_base]'

  # Recharger le parametrage de base
  bin/rake 'sylrplm:import_domain[db/custos/sicm,sicm.custo]'

  # Recharger un exemple de projet
  bin/rake 'sylrplm:import_domain[db/custos/sicm,sample.table]'

  # Lancer le gestionnaire de taches:notifications
  bin/rake sylrplm:run_scheduler
  ```
- Créer le fichier `.env` qui contient les variables d'environnement utilisées par l' app:
    ```
    cp .env.example .env
    ```
- Lancer l' app:
  ```
  # Avec la Heroku toolbelt
  heroku local

  # ou sans
  bin/rails server
  ```
- [Visiter `localhost:3000`](http://localhost:3000)

### Voir les mails "envoyés" en développement ou en staging

En développement, tout mail "envoyé" est automatiquement ouvert dans le
navigateur au lieu d'être réellement envoyé.

Pour voir un historique de tous les mails "envoyés", vous pouvez visiter
http://localhost:3000/mails.

En staging, les mails ne sont pas ouverts automatiquement, mais toujours visible
à l'adresse http://sylrplm-staging.herokuapp.com/mails.

## Déploiement sur Heroku

- [Installer la Heroku Toolbelt](https://toolbelt.heroku.com)
- Enregistrer les remotes de staging et production:
  ```
  heroku git:remote --remote production --app sylrplm
  heroku git:remote --remote staging --app sylrplm-staging
  ```
- Déployer:
  ```
  heroku push staging

  # ou pour déployer une branche particulière en staging
  heroku push staging ma_branche:master

  # ou en production (seulement master donc ne jamais passer ma_branche:master)
  heroku push production
  ```
- Lancer les migrations (si besoin):
  ```
  heroku run rake db:migrate --remote staging

  # ou en production
  heroku run rake db:migrate -r production
  ```
