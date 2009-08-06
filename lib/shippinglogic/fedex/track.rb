module Shippinglogic
  class FedEx
    # An interface to the track services provided by FedEx. Allows you to get an array of events for a specific
    # tracking number.
    #
    # == Accessor methods / options
    #
    # * <tt>tracking_number</tt> - the tracking number
    #
    # === Simple Example
    #
    # Here is a very simple example:
    #
    #   fedex = Shippinglogic::FedEx.new(key, password, account, meter)
    #   fedex.track(:tracking_number => "my number")
    #
    # === Note
    # FedEx does support locating packages through means other than a tracking number.
    # These are not supported and probably won't be until someone needs them. It should
    # be fairly simple to add, but I could not think of a reason why anyone would want to track
    # a package with anything other than a tracking number.
    class Track < Service
      # Each tracking result is an object of this class
      class Event; attr_accessor :name, :type, :occured_at, :city, :state, :postal_code, :country, :residential; end
      
      VERSION = {:major => 3, :intermediate => 0, :minor => 0}
      
      attribute :tracking_number, :string
      
      private
        def target
          @target ||= parse_track_response(request(build_track_request))
        end
        
        def build_track_request
          b = builder
          xml = b.TrackRequest(:xmlns => "http://fedex.com/ws/track/v#{VERSION[:major]}") do
            build_authentication(b)
            build_version(b, "trck", VERSION[:major], VERSION[:intermediate], VERSION[:minor])
            
            b.PackageIdentifier do
              b.Value tracking_number
              b.Type "TRACKING_NUMBER_OR_DOORTAG"
            end
            
            b.IncludeDetailedScans true
          end
        end
        
        def parse_track_response(response)
          response[:track_details][:events].collect do |details|
            event = Event.new
            event.name = details[:event_description]
            event.type = details[:event_type]
            event.occured_at = Time.parse(details[:timestamp])
            event.city = details[:address][:city]
            event.state = details[:address][:state_or_province_code]
            event.postal_code = details[:address][:postal_code]
            event.country = details[:address][:country_code]
            event.residential = details[:address][:residential] == "true"
            event
          end
        end
    end
  end
end