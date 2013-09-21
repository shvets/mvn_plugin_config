require 'lib/mvn_plugin_config/app'

Rack::Handler::Mongrel.run App.new, :Port => 4567