module RaspApi
  def self.get_stops coords
    "http://rasp.orgp.spb.ru/?lat=#{coords.latitude}&lng=#{coords.longitude}"
  end
end