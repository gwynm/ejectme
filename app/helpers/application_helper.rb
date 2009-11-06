# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def wikipedia_link(str)
    link_to str,"http://en.wikipedia.org/wiki/Special:Search/" + str + "_" + "airport"
  end
end
