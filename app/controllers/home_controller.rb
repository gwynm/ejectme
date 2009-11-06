class HomeController < ApplicationController
  def index
    @flights = EjectorSeat.eject
    redirect_to ejector_malfunction_path and return unless @flights
  end
  def ejector_malfunction
  end
end
