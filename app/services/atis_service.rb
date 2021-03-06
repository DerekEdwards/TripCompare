require "net/http"
require 'logger'

class AtisService

  ## Format of trip_params ##  
  # {
  #   origin: {lat: self.origin_lat, lng: self.origin_lng},
  #   destination: {lat: self.destination_lat, lng: self.destination_lng}, 
  #   time: self.time,
  #   arrive_by: self.arrive_by
  # }

  attr_accessor :app_id, :base_url

  def initialize(base_url, app_id)
      @app_id = app_id
      @base_url = base_url
  end

  ## Send the Requests
  def plan_trip trip_params
    type = 'post'
    url = @base_url
    uri = URI.parse(url)
    case type.downcase
      when 'post'
        req = Net::HTTP::Post.new(uri.path)
        req.body = plan_body trip_params
      when 'delete'
        req = Net::HTTP::Delete.new(uri.path)
      else
        req = Net::HTTP::Get.new(uri)
    end

    puts req.body
    req.add_field 'Content-Type', 'text/xml'

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = 's'.in? url[0..4]
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    begin
      resp = http.start {|http| http.request(req)}
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
        Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::ProtocolError => e
        resp.body = nil
    end
    return req.body, resp.body

  end

  def plan_body trip_params
    xmode = trip_params[:atis_mode].empty? ? "BCXTFRSLK123" : trip_params[:atis_mode]
    "<?xml version='1.0' encoding='UTF-8'?>
    <SOAP-ENV:Envelope xmlns:xsi='http://www.w3.org/1999/XMLSchema-instance' xmlns:SOAP-ENC='http://schemas.xmlsoap.org/soap/encoding/' xmlns:SOAP-ENV='http://schemas.xmlsoap.org/soap/envelope/' xmlns:xsd='http://www.w3.org/1999/XMLSchema' SOAP-ENV:encodingStyle='http://schemas.xmlsoap.org/soap/encoding/'>
    <SOAP-ENV:Body>
    <namesp1:Plantrip xmlns:namesp1='NY_SOAP2'>
      <Appid>#{@app_id}</Appid>
      <Originlat>#{trip_params[:origin][:lat]}</Originlat>
      <Originlong>#{trip_params[:origin][:lng]}</Originlong>
      <Origintext>Origin Name</Origintext>
      <Destinationlat>#{trip_params[:destination][:lat]}</Destinationlat>
      <Destinationlong>#{trip_params[:destination][:lng]}</Destinationlong>
      <Destinationtext>Destination Name</Destinationtext>
      <Time>#{trip_params[:time].strftime("%H%M")}</Time>
      <Date>#{trip_params[:time].strftime("%D")}</Date>
      <Minimize>#{trip_params[:atis_minimize] || 'T'}</Minimize>
      <Accessible>#{trip_params[:atis_accessible] ? 'Y' : 'N'}</Accessible>
      <Arrdep>#{trip_params[:arrive_by] ? 'A' : 'D'}</Arrdep>
      <Walkdist>#{((trip_params[:atis_walk_dist] || 1609.34)/1609.34).round(2)}</Walkdist>
      <Walkspeed>#{((trip_params[:atis_walk_speed] || 1.34112)*2.23694).round(2)}</Walkspeed>
      <Walkincrease>N</Walkincrease>
      <Maxanswers>3</Maxanswers>
      <Maxtransfers>3</Maxtransfers>
      <Debug>1</Debug>
      <Xmode>#{xmode}</Xmode>
    </namesp1:Plantrip>
    </SOAP-ENV:Body>
    </SOAP-ENV:Envelope>"
  end

end
 