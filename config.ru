# To use with thin 
#  thin start -p PORT -R config.ru
require File.join(File.dirname(__FILE__), 'lib', 'mvn_plugin_config')

trap(:INT) { exit }

app = Rack::Builder.new {
  use Rack::CommonLogger
 run MvnPluginConfig::App
}.to_app

run app

#require 'vegas'
#
#Vegas::Runner.new(MvnPluginConfig::App, 'mvn_plugin_config')

#require 'launchy'
#
#Launchy.open("http://localhost:9292", :application => MvnPluginConfig::App)
