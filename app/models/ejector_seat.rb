class EjectorSeat
  
  #Find a suitable flight pair, or return nil if there's nothing
  def self.eject
    ejections = []
    self.upcoming_outgoing_dates.each do |outgoing|
      RAILS_DEFAULT_LOGGER.info "GWYN: trying date #{outgoing}"
      outgoing_flights = self.find_flights_for_date(:from=>"STN",:to=>nil,:max_price=>20,:date=>outgoing)
      next if outgoing_flights.nil?
      outgoing_flights.each do |outgoing_flight|
        RAILS_DEFAULT_LOGGER.info "GWYN:   flying out on #{outgoing_flight.inspect}"
        next unless outgoing_flight
        incoming_flight = self.find_flight_for_date(:from=>outgoing_flight.to_airport,:to=>"STN",:max_price=>20,:date=>incoming_date(outgoing))
        ejections << {:outgoing=>outgoing_flight,:incoming=>incoming_flight} if incoming_flight
        RAILS_DEFAULT_LOGGER.info "GWYN:    agh, can't get home on #{incoming_date(outgoing)}!"
      end
    end  
    return ejections
  end
  

  #return a flight object, or nil
  def self.find_flights_for_date(params)
    cond_hash = {}
    cond_string = []
    if params[:from]
      cond_hash[:from] = params[:from]
      cond_string << "from_airport = :from"
    end
    if params[:to]
      cond_hash[:to] = params[:to]
      cond_string << "to_airport = :to"
    end
    if params[:max_price]
      cond_hash[:max_price] = params[:max_price]
      cond_string << "price < :max_price"
    end
    if params[:date]
      cond_hash[:min_date] = DateTime.parse(params[:date].strftime("%Y-%m-%d") + " 00:00")
      cond_hash[:max_date] = DateTime.parse(params[:date].strftime("%Y-%m-%d") + " 23:59")
      cond_string << "departs_at > :min_date AND departs_at < :max_date"
    end
    Flight.find(:all,:conditions=>[cond_string.join(" AND "),cond_hash])
  end
  
  def self.find_flight_for_date(params)
    self.find_flights_for_date(params).sort_by{rand}.first
  end
  
  def self.upcoming_outgoing_dates
    (0..40).collect{|n| n.days.from_now}.select{|d| %w(Fri Sat).include?(d.strftime("%a"))}.compact
  end
    
  def self.incoming_date(outgoing)
    outgoing + 2.days #fri->sun or sat->mon
  end
    
  
end
