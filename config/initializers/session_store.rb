# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_sylrplm_session',
  :secret      => 'be7b95b28c18fa807a9cfd6656cf066609e433a201e705e11824335835397b0c1325ceb29ea1994b073afa4254cb7dcef7709c5d621c3a74015c1f19e469b010'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
