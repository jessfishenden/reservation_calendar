ActiveRecord::Base.extend ReservationCalendar::PluginMethods
ActionView::Base.send :include, ReservationCalendar::CalendarHelper
