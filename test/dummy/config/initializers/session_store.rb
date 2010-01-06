# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_dummy_session',
  :secret      => '030bccc601f83ab27ce1d84f5ed14dac11d979ec33cb7e4ac06525444862f9180b5c13e1d07cde78d040a5ef66fcbfcdcb6981c2e9bbd4a445c70bc6166e2be3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
