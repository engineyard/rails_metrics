# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key    => '_dummy_session',
  :secret => '3bd151c2e33fc860c04c1deb5b9b456f800c6b737fc30f4bac49cb3363e3f806e8529e8b5d18fc324b4de08bc37b01b245f2cb380dbe43d5284438598ec35b3f'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
