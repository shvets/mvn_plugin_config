require 'rubygems' unless RUBY_VERSION =~ /1.9.*/

require 'sinatra/base'
require 'haml'
require 'sass'
require 'zip/zip'
require 'nokogiri'

$:.unshift(File.expand_path(File.join(File.dirname(__FILE__))))

require 'partial'
require 'directory_scanner'
require 'plugin_info'
require 'mojo_info'

module MvnPluginConfig
class App < Sinatra::Base
  MAVEN_REPOSITORY = "#{ENV['HOME']}/.m2/repository"
     
  set :haml, {:format => :html5, :attr_wrapper => '"'}
  set :views, "#{File.expand_path(File.dirname(__FILE__))}/../../views"
  set :public_dir, "#{File.expand_path(File.dirname(__FILE__))}/../../public"
   
#   get '/javascripts/*' do
#     open("#{File.dirname(__FILE__)}/../public/javascripts/#{params[:splat]}")
#   end
  
  get '/stylesheet.css' do
    headers 'Content-Type' => 'text/css; charset=utf-8'
    sass :stylesheet
  end

  get '/' do
    if File.exist? MAVEN_REPOSITORY
      haml :index, :locals => {:plugins => collect_plugins_info}
    else
      haml :no_maven_repo
    end
  end
 
   get '/*:*:*' do
    plugin_file_content = plugin_file_content(params[:splat][0], params[:splat][1], params[:splat][2])
    
    haml :description, :locals => {:mojos => collect_mojos_info(plugin_file_content)}
   end
 
  private

  def jar_file_name group_id, artifact_id, version
    "#{MAVEN_REPOSITORY}/#{group_id.gsub('.', '/')}/#{artifact_id}/#{version}/#{artifact_id}-#{version}.jar"  
  end

  def plugin_file_content group_id, artifact_id, version
    plugin_file_content = nil
        
    jar_file_name = jar_file_name(group_id, artifact_id, version)
    
    Zip::ZipInputStream.open(jar_file_name) do |zis|
      done = false
      while (not done) do
        entry = zis.get_next_entry
        if entry.name == "META-INF/maven/plugin.xml"
          plugin_file_content = zis.read
          done = true
        end
      end
    end
    
    plugin_file_content    
  end
  
  def collect_plugins_info
    plugins = []
 
    scanner = DirectoryScanner.new
 
    scanner.on_dir do |file, path|
      if file =~ /-plugin$/
        directories = scanner.directories_in_parent(path)
        
        directories.each do |version|
          group_id = path[MAVEN_REPOSITORY.length+1..path.length-file.length-2].gsub('/', '.')
          artifact_id = file.gsub('/', '.')
          
          jar_file_name = jar_file_name(group_id, artifact_id, version)
              
          plugins << PluginInfo.new(group_id, artifact_id, version) if File.exist?(jar_file_name)         
        end
      end 
    end
    
    scanner.scan_subtree(MAVEN_REPOSITORY)
    
    plugins
  end
  
  def collect_mojos_info content
    mojos = []
 
    doc = Nokogiri::XML(content)
     
     doc.xpath('//mojos/mojo').each do |node|
       goal = node.xpath('goal')
       description = node.xpath('description')
       
       parameters = collect_parameters(node.xpath('parameters'))
       configuration = node.xpath('configuration')
       
       mojos << MojoInfo.new(goal, description, parameters, configuration)
     end
    
    mojos
  end
  
  def collect_parameters(node)
    parameters = []
    
    node.children.each do |param_node|
      if param_node.name == 'parameter'
        parameter = {:name => param_node.xpath('name'), :type => param_node.xpath('type'),
                     :required => param_node.xpath('required'), :editable => param_node.xpath('editable'),
                     :description => param_node.xpath('description')}
        parameters << parameter
      end
    end
    
    parameters
  end
       
  helpers do
    include Partial
    include Rack::Utils
    
    alias_method :h, :escape_html
  end
end
end

