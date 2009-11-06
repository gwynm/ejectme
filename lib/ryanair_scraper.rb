class RyanairScraper < Scraper
  
  def self.build_all_flights
    from_airport = "STN"
    to_airports = %w(RYG ORK NRN NOC LRH MRS PMF PEG PIS NYO)

    to_airports.each do |to_airport|
      upcoming_dates.each do |date|
        self.build_flights(date,from_airport,to_airport)
        puts "#{from_airport} -> #{to_airport} on #{date.to_s}"
      end
    end
  end
  
  def self.upcoming_dates
    (1..30).collect{|n| n.days.from_now}.select{|d| %w(Fri Sat Sun Mon).include?(d.strftime("%a"))}.compact
  end
    
  #Query ryanair and create a Flight object 
  def self.build_flights(date,from_string,to_string)
    agent = WWW::Mechanize.new
    #agent.set_proxy("127.0.0.1", 8888)
    page = agent.get('http://ryanair.com/php/sbforms/form.php?val=GB')
    booking_form = page.forms.first
    booking_form.sector1_o = "a" + from_string
    booking_form.sector1_d = to_string
    booking_form.delete_field!("SearchBy")
    booking_form.date1 = date.strftime("%Y%m%d")
    booking_form.date2 = date.strftime("%Y%m%d")
    booking_form.m1 = date.strftime("%Y%m%d") + "a" + from_string + to_string
    booking_form.m1 = date.strftime("%Y%m%d") + to_string + "a" + from_string
    booking_form.nom = "2"
    booking_form.pM = "0"
    booking_form.tc = "1"
    booking_form.pT = "1ADULT"
    booking_form.sector_1_d = date.strftime("%d")
    booking_form.sector_1_m = date.strftime("%m%Y")
    booking_form.sector_2_d = date.strftime("%d")
    booking_form.sector_2_m = date.strftime("%m%Y")
    booking_form.add_field!("travel_type","on")
    results_page = agent.submit(booking_form)
    
    return nil unless results_page.root.to_s.index("Regular") #no flights on this date
        
    #now break out the flight keys
    outgoing_keys = self.get_keys(results_page,"AvailabilityInputFRSelectView$market1")
    incoming_keys = self.get_keys(results_page,"AvailabilityInputFRSelectView$market2")

    #get the prices
    best_outgoing_price = self.best_price(agent,outgoing_keys)
    best_incoming_price = self.best_price(agent,incoming_keys)
        
    #later, get date from the key
    Flight.create!(:from_airport=>from_string,:to_airport=>to_string,:departs_at=>date,:price=>best_outgoing_price) if best_outgoing_price
    Flight.create!(:from_airport=>to_string,:to_airport=>from_string,:departs_at=>date,:price=>best_incoming_price) if best_incoming_price
  end
  
private

  def self.best_price(agent,keys)
    prices = []
    keys.each do |key|
      detail = agent.get("http://www.bookryanair.com/skysales/FRTaxAndFeeInclusiveDisplay-resource.aspx?flightKeys=#{key}&numberOfMarkets=1&keyDelimeter=+++")
      prices << self.get_price_from_detail_page(detail)
    end
    prices.compact.sort.uniq.first
  end

  def self.get_keys(results_page,v)
    keys = []
    results_page.search("//input").each do |inp|
      if inp.attributes["name"].to_s.strip == v
        keys << inp.attributes["value"].to_s.strip
      end
    end
    keys
  end
    
  def self.get_price_from_detail_page(detail_page)
    detail_page.search("//td")[-2].children.to_s.to_f 
  end
  
end