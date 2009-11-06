# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_ejectme_session',
  :secret      => '7172a28d6edc1dbd65693cc8eeb39f4bda433149e8fffa4d73b95ad8e858f5aaafe98498c3ac3a046f44aad18894700112f29400ffef6cfa1f318d2a06fd32ac'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
