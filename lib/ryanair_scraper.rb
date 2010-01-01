class RyanairScraper < Scraper
  
  def self.build_all_flights
    self.prune_old_data
    
    from_airport = "STN"
    all_dest_airports = %w(AAR AGA AHO ALC LEI AOC AOI ANG BAR BRI BSL BHD EGC SXF BIQ BLL BLQ BTS BRE BDS BRQ BZG CCF ORK CUF LDY DNR DUB NRN EIN FAO HHN FDH GDN GOA GRO PIK GSE LPA GRX GRZ GNB LBC HAU IBZ XRY FKB KTW KUN KIR KLU NOC KRK LRH ACE LIG LNZ LCJ LDE MAD AGP MRS FMM BGY MPL MUN MJV RYG TRF PMO PMI PMF PUF PGF PEG PSR PSA PIS OPO POZ PUY REU RIX RMI RDZ CIA RZE SZG SDR SCQ SVQ SNN NYO VST SZZ TMP TFS TLN TUF TRS TRN VLC VLL TSF VBS WRO ZAD ZAZ)
    warm_places = %w(TFS LPA ACE AGA FAO XRY AGP LEI MJV SVQ GRX IBZ AHO TPS PMO BRI BDS)
    
    to_airports = warm_places
    

    to_airports.each do |to_airport|
      upcoming_dates.each do |date|
        puts "#{from_airport} -> #{to_airport} on #{date.to_s}"
        if EjectorSeat.find_flight_for_date(:date=>date,:from=>from_airport,:to=>to_airport) 
          puts " Existing."
        else
          o,i=self.build_flights(date,from_airport,to_airport) #if there's any match, don't check again
          if o.nil? and i.nil?
            puts " Found no flights!" 
          else  
            puts " Found flights #{o}, #{i}"
          end
        end
      end
    end
    puts Time.now
  end
  
  def self.prune_old_data
    Flight.destroy_all(["created_at < ?",2.days.ago])
  end
  
  def self.upcoming_dates
    (1..30).collect{|n| n.days.from_now}.select{|d| %w(Fri Sat Sun Mon).include?(d.strftime("%a"))}.compact
  end
    
  #Query ryanair and create a Flight object 
  def self.build_flights(date,from_string,to_string)
    begin
      agent = WWW::Mechanize.new
     # agent.set_proxy("127.0.0.1", 8888)
      page = agent.get('http://ryanair.com/en/booking/form')
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
  #  return results_page
      return nil unless results_page.root.to_s.index("Adult") #no flights on this date
        
      #now break out the flight keys
      outgoing_keys = self.get_keys(results_page,"AvailabilityInputFRSelectView$market1")
      incoming_keys = self.get_keys(results_page,"AvailabilityInputFRSelectView$market2")

      #get the prices
      best_outgoing_price = self.best_price(agent,outgoing_keys)
      best_incoming_price = self.best_price(agent,incoming_keys)
        
      #later, get date from the key
      Flight.create!(:from_airport=>from_string,:to_airport=>to_string,:departs_at=>date,:price=>best_outgoing_price) if best_outgoing_price
      Flight.create!(:from_airport=>to_string,:to_airport=>from_string,:departs_at=>date,:price=>best_incoming_price) if best_incoming_price
      return [best_outgoing_price,best_incoming_price]
    rescue SystemCallError
      puts "Hrm, timed out. Just skipping that one."
    end
  end
  
private

  def self.best_price(agent,keys)
    begin
      prices = []
      keys.each do |key|
        detail = agent.get("http://www.bookryanair.com/skysales/FRTaxAndFeeInclusiveDisplay-resource.aspx?flightKeys=#{key}&numberOfMarkets=1&keyDelimeter=+++")
        prices << self.get_price_from_detail_page(detail)
      end
      prices.compact.sort.uniq.first
    rescue WWW::Mechanize::ResponseCodeError
      RAILS_DEFAULT_LOGGER.info("GWYN: ERROR: DIED ON KEYS #{keys.inspect}")
    end
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