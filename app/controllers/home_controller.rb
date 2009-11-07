class HomeController < ApplicationController
  def index
    @ejections = EjectorSeat.eject
    @flights = @ejections.sort_by{rand}.first
    redirect_to ejector_malfunction_path and return unless @flights
  end
  def ejector_malfunction
  end
end
