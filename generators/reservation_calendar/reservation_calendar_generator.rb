require File.expand_path(File.dirname(__FILE__) + "/lib/insert_routes.rb")

class ReservationCalendarGenerator < Rails::Generator::Base
  default_options :static_only => false
  
  attr_reader :class_name, :subclass_name, :view_name
  
  def initialize(args, options = {})
    super
    usage if args.length > 0 and args.length < 3
    @class_name = (args.shift || "reservation").underscore
    @subclass_name = (args.shift || "reserved_date").underscore
    @view_name = (args.shift || "calendar").underscore
  end
  
  def manifest
    record do |m|
      # static files
      m.directory File.join("public/stylesheets")
      m.file "stylesheet.css", "public/stylesheets/reservation_calendar.css"
      
			script = options[:use_jquery] ? 'jq_javascript.js' : 'javascript.js'
		  m.file script, "public/javascripts/reservation_calendar.js"
      
      # MVC and other supporting files
      unless options[:static_only]
        m.directory File.join("app/models")
        m.template "model.rb.erb", File.join("app/models", "#{@class_name}.rb")
        m.template "subclass_model.rb.erb", File.join("app/models", "#{@subclass_name}.rb")
        m.template "calendar_controller.rb.erb", File.join("app/controllers", "#{@view_name}_controller.rb")
        m.template "reservation_controller.rb.erb", File.join("app/controllers", "#{@class_name.pluralize}_controller.rb")
        
        m.directory File.join("app/views")
        m.directory File.join("app/views", @view_name)
        m.directory File.join("app/views", @class_name.pluralize)
        m.template "view.html.erb", File.join("app/views", @view_name, "index.html.erb")
        m.template "reservation_show_view.rb.erb", File.join("app/views", @class_name.pluralize,"show.html.erb")
        m.directory File.join("app/helpers")
        m.template "helper.rb.erb", File.join("app/helpers", "#{@view_name}_helper.rb")
        m.migration_template "migration.rb.erb", "db/migrate", :migration_file_name => "create_#{@class_name.pluralize}_and_#{@subclass_name.pluralize}"
        m.route_name(@view_name, "#{@view_name}", ":controller => '#{@view_name}', :action => 'index', :year => Time.zone.now.year, :month => Time.zone.now.month")
        m.route_name("connect", "/#{@view_name}/:year/:month", ":controller => '#{@view_name}', :action => 'index', :year => Time.zone.now.year, :month => Time.zone.now.month")
        m.route_resource(@class_name.pluralize)
        
        # generate the specs
        m.directory File.join("spec")
        m.template "spec.blueprints.rb.erb", File.join("spec", "blueprints.rb")
        m.directory File.join("spec/controllers")
        m.template "spec.reservations_controller_spec.rb.erb", File.join("spec/controllers", "#{@class_name.pluralize}_controller_spec.rb")
        m.template "spec.calendar_controller_spec.rb.erb", File.join("spec/controllers", "#{@view_name}_controller_spec.rb")
        m.directory File.join("spec/models")
        m.template "spec.reservation_spec.rb.erb", File.join("spec/models", "#{@class_name}_spec.rb")
        m.template "spec.reserved_date_spec.rb.erb", File.join("spec/models", "#{@subclass_name}_spec.rb")
   
      end
    end
  end
  
  protected
  
  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--static-only",
      "Only generate the static files. (stylesheet, javascript, and images)") { |v| options[:static_only] = v }
    opt.on("--use-jquery",
      "Use jquery template file when generating the javascript.") { |v| options[:use_jquery] = v }
  end
end
