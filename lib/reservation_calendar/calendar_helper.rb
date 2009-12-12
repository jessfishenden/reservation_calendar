module ReservationCalendar
  module CalendarHelper
 
    # Returns an HTML calendar which can show multiple, overlapping reservations across calendar days and rows.
    # Customize using CSS, the below options, and by passing in a code block.
    #
    # The following are optional, available for customizing the default behaviour:
    # :month => Time.now.month # The month to show the calendar for. Defaults to current month.
    # :year => Time.now.year # The year to show the calendar for. Defaults to current year.
    # :abbrev => (0..2) # This option specifies how the day names should be abbreviated.
    #     Use (0..2) for the first three letters, (0..0) for the first, and
    #     (0..-1) for the entire name.
    # :first_day_of_week => 0 # Renders calendar starting on Sunday. Use 1 for Monday, and so on.
    # :show_today => true # Highlights today on the calendar using CSS class.
    # :month_name_text => nil # Displayed center in header row.
    #     Defaults to current month name from Date::MONTHNAMES hash.
    # :previous_month_text => nil # Displayed left of the month name if set
    # :next_month_text => nil # Displayed right of the month name if set
    # :reservation_strips => [] # An array of arrays, encapsulating the reservation rows on the calendar
    # :width => nil # Width of the calendar, if none is set then it will stretch the container's width
    # :height => 500 # Approx minimum total height of the calendar (excluding the header).
    #     Height could get added if a day has too many reservation's to fit.
    # :day_names_height => 18 # Height of the day names table (included in the above 'height' option)
    # :day_nums_height => 18 # Height of the day numbers tables (included in the 'height' option)
    # :reservation_height => 18 # Height of an individual reservation row
    # :reservation_margin => 1 # Spacing of the reservation rows
    # :reservation_padding_top => 1 # Padding on the top of the reservation rows (increase to move text down)
    # :use_javascript => true # Outputs HTML with inline javascript so reservations spanning multiple days will be highlighted.
    #     If this option is false, cleaner HTML will be output, but reservations spanning multiple days will 
    #     not be highlighted correctly on hover, so it is only really useful if you know your calendar
    #     will only have single-day reservations. Defaults to true.
    # :link_to_day_action => false # If controller action is passed,
    #     the day number will be a link. Override the day_link method for greater customization.
    #
    # For more customization, you can pass a code block to this method
    #
    # For example usage, see README.
    #
    def calendar(options = {}, &block)
      block ||= Proc.new {|d| nil}
 
      defaults = {
        :year => Time.zone.now.year,
        :month => Time.zone.now.month,
        :abbrev => (0..2),
        :first_day_of_week => 0,
        :show_today => true,
        :month_name_text => Time.zone.now.strftime("%B %Y"),
        :previous_month_text => nil,
        :next_month_text => nil,
        :reservation_strips => [],
        
        # it would be nice to have these in the CSS file
        # but they are needed to perform height calculations
        :width => nil,
        :height => 500, 
        :day_names_height => 18,
        :day_nums_height => 18,
        :reservation_height => 18,
        :reservation_margin => 1,
        :reservation_padding_top => 1,
        
        :use_javascript => true,
        :link_to_day_action => false
      }
      options = defaults.merge options
    
      # default month name for the given number
      options[:month_name_text] ||= Date::MONTHNAMES[options[:month]]
      
      # make the height calculations
      # tricky since multiple reservations in a day could force an increase in the set height
      height = options[:day_names_height]
      row_heights = cal_row_heights(options)
      row_heights.each do |row_height|
        height += row_height
      end
      
      # the first and last days of this calendar month
      first = Date.civil(options[:year], options[:month], 1)
      last = Date.civil(options[:year], options[:month], -1)
      
      # create the day names array [Sunday, Monday, etc...]
      day_names = Date::DAYNAMES.dup
      options[:first_day_of_week].times do
        day_names.push(day_names.shift)
      end
 
      # Build the HTML string
      cal = ""
      
      # outer calendar container
      cal << %(<div class="ec-calendar")
      cal << %(style="width: #{options[:width]}px;") if options[:width]
      cal << %(>)
      
      # table header, including the monthname and links to prev & next month
      cal << %(<table class="ec-calendar-header" cellpadding="0" cellspacing="0">)
      cal << %(<thead><tr>)
      if options[:previous_month_text] or options[:next_month_text]
        cal << %(<th colspan="2" class="ec-month-nav">#{options[:previous_month_text]}</th>)
        colspan = 3
      else
        colspan = 7
      end
      cal << %(<th colspan="#{colspan}" class="ec-month-name">#{options[:month_name_text]}</th>)
      if options[:next_month_text]
        cal << %(<th colspan="2" class="ec-month-nav">#{options[:next_month_text]}</th>)
      end
      cal << %(</tr></thead></table>)
      
      # body container (holds day names and the calendar rows)
      cal << %(<div class="ec-body" style="height: #{height}px;">)
      
      # day names 
      cal << %(<table class="ec-day-names" style="height: #{options[:day_names_height]}px;" cellpadding="0" cellspacing="0">)
      cal << %(<tbody><tr>)
      day_names.each do |day_name|
        cal << %(<th class="ec-day-name" title="#{day_name}">#{day_name.mb_chars[options[:abbrev]]}</th>)
      end
      cal << %(</tr></tbody></table>)
      
      # container for all the calendar rows
      cal << %(<div class="ec-rows" style="top: #{options[:day_names_height]}px; )
      cal << %(height: #{height - options[:day_names_height]}px;">)
      
      # initialize loop variables
      first_day_of_week = beginning_of_week(first, options[:first_day_of_week])
      last_day_of_week = end_of_week(first, options[:first_day_of_week])
      last_day_of_cal = end_of_week(last, options[:first_day_of_week])
      row_num = 0
      top = 0
      
      # go through a week at a time, until we reach the end of the month
      while(last_day_of_week <= last_day_of_cal)
        cal << %(<div class="ec-row" style="top: #{top}px; height: #{row_heights[row_num]}px;">)
        top += row_heights[row_num]
        
        # this weeks background table
        cal << %(<table class="ec-row-bg" cellpadding="0" cellspacing="0">)
        cal << %(<tbody><tr>)
        first_day_of_week.upto(first_day_of_week+6) do |day|
          today_class = (day == Date.today) ? "ec-today-bg" : ""
          cal << %(<td class="ec-day-bg #{today_class}">&nbsp;</td>)
        end
        cal << %(</tr></tbody></table>)
        
        # calendar row
        cal << %(<table class="ec-row-table" cellpadding="0" cellspacing="0">)
        cal << %(<tbody>)
        
        # day numbers row
        cal << %(<tr>)
        first_day_of_week.upto(last_day_of_week) do |day|
          cal << %(<td class="ec-day-header )
          cal << %(ec-today-header ) if options[:show_today] and (day == Date.today)
          cal << %(ec-other-month-header ) if (day < first) || (day > last)
          cal << %(ec-weekend-day-header) if weekend?(day)
          cal << %(" style="height: #{options[:day_nums_height]}px;">)
          if options[:link_to_day_action]
            cal << day_link(day.day, day, options[:link_to_day_action])
          else
            cal << %(#{day.day})
          end
          cal << %(</td>)
        end
        cal << %(</tr>)
        
        # reservation rows for this day
        # for each reservation strip, create a new table row
        options[:reservation_strips].each do |strip|
          cal << %(<tr>)
          # go through through the strip, for the entries that correspond to the days of this week
          strip[row_num*7, 7].each_with_index do |reservation, index|
            day = first_day_of_week + index
            
            if reservation
              # get the dates of this reservation that fit into this week
              dates = reservation.reserved_dates.clip(first_day_of_week, last_day_of_week)
              # if the reservation (after it has been clipped) starts on this date,
              # then create a new cell that spans the number of days
              if dates[0].date == day.to_date
                
                cal << %(<td class="ec-reservation-cell" colspan="#{(dates[1].date-dates[0].date).to_i + 1}" )
                cal << %(style="padding-top: #{options[:reservation_margin]}px;">)
                cal << %(<div class="ec-reservation reservation_#{reservation.id}" )
                cal << %(style="background-color: #{reservation.color}; )
                cal << %(padding-top: #{options[:reservation_padding_top]}px; )
                cal << %(height: #{options[:reservation_height] - options[:reservation_padding_top]}px;" )
                if options[:use_javascript]
                  cal << %(reservation_id="#{reservation.id}" color="#{reservation.color}" )
                  cal << %(onmouseover="select_reservation(this, true);" onmouseout="select_reservation(this, false);" )
                end
                cal << %(>)
                
                # add a left arrow if reservation is clipped at the beginning
                if reservation.reserved_dates.first.date < dates[0].date
                  cal << %(<div class="ec-left-arrow"></div>)
                end
                # add a right arrow if reservation is clipped at the end
                if reservation.reserved_dates.last.date > dates[1].date
                  cal << %(<div class="ec-right-arrow"></div>)
                end
                
                # add the additional html that was passed as a block to this helper
                cal << block.call(reservation)
                
                cal << %(</div></td>)
              end
              
            else
              # there wasn't a reservation, so create an empty cell and container
              cal << %(<td class="ec-reservation-cell ec-no-reservation-cell" )
              cal << %(style="padding-top: #{options[:reservation_margin]}px;">)
              cal << %(<div class="ec-reservation" )
              cal << %(style="padding-top: #{options[:reservation_padding_top]}px; )
              cal << %(height: #{options[:reservation_height] - options[:reservation_padding_top]}px;" )
              cal << %(>)
              cal << %(&nbsp;</div></td>)
            end
          end
          cal << %(</tr>)
        end
        
        cal << %(</tbody></table>)
        cal << %(</div>)
        
        # increment the calendar row we are on, and the week
        row_num += 1
        first_day_of_week += 7
        last_day_of_week += 7
      end      
    
      cal << %(</div>)   
      cal << %(</div>)
      cal << %(</div>)
    end
    
    # override this in your own helper for greater control
    def day_link(text, date, day_action)
      link_to(text, params.merge(:action => day_action, :day => date.day), :class => 'ec-day-link')
    end
  
    private
    
    # calculate the height of each row
    # by default, it will be the height option minus the day names height,
    # divided by the total number of calendar rows
    # this gets tricky, however, if there are too many reservation rows to fit into the row's height
    # then we need to add additional height
    def cal_row_heights(options)
      # number of rows is the number of days in the reservation strips divided by 7
      num_cal_rows = options[:reservation_strips].first.size / 7
      # the row will be at least this big
      min_height = (options[:height] - options[:day_names_height]) / num_cal_rows
      row_heights = []
      num_reservation_rows = 0
      # for every day in the reservation strip...
      1.upto(options[:reservation_strips].first.size+1) do |index|
        num_reservations = 0
        # get the largest reservation strip that has a reservation on this day
        options[:reservation_strips].each_with_index do |strip, strip_num|
          num_reservations = strip_num + 1 unless strip[index-1].blank?
        end
        # get the most reservation rows for this week
        num_reservation_rows = [num_reservation_rows, num_reservations].max
        # if we reached the end of the week, calculate this row's height
        if index % 7 == 0
          total_reservation_height = options[:reservation_height] + options[:reservation_margin]
          calc_row_height = (num_reservation_rows * total_reservation_height) + options[:day_nums_height] + options[:reservation_margin]
          row_height = [min_height, calc_row_height].max
          row_heights << row_height
          num_reservation_rows = 0
        end
      end
      row_heights
    end
  
    #
    # helper methods for working with a calendar week
    #
    
    def days_between(first, second)
      if first > second
        second + (7 - first)
      else
        second - first
      end
    end
  
    def beginning_of_week(date, start = 0)
      days_to_beg = days_between(start, date.wday)
      date - days_to_beg
    end
    
    def end_of_week(date, start = 0)
      beg = beginning_of_week(date, start)
      beg + 6
    end
  
    def weekend?(date)
      [0, 6].include?(date.wday)
    end
  end
end
