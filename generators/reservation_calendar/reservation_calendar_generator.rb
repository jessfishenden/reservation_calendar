
class ReservationCalendarGenerator < Rails::Generator::Base
  default_options :static_only => false
  
  attr_reader :class_name, :subclass_name, :view_name
  
  def initialize(args, options = {})
    super
  end
  
  def manifest
    record do |m|
      # static files
      m.directory File.join("public/stylesheets")
      m.file "stylesheet.css", "public/stylesheets/reservation_calendar.css"
      
			script = options[:use_jquery] ? 'jq_javascript.js' : 'javascript.js'
		  m.file script, "public/javascripts/reservation_calendar.js"
	  end
  end
  
  protected
  
  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on("--use-jquery",
      "Use jquery template file when generating the javascript.") { |v| options[:use_jquery] = v }
  end
end
