class HomeController < ApplicationController
  def index
    @flights = EjectorSeat.eject
    redirect_to ejector_malfunction_path and return unless @flights
  end
  def ejector_malfunction
    render :text=>"Mayday! Can't eject!<br/><img src='http://i.thisislondon.co.uk/i/pix/2008/12/plane-crash-houses-415x275.jpg'>"
  end
end
