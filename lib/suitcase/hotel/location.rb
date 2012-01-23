module Suitcase
  class Hotel
    class Location
      extend Suitcase::Helpers

      attr_accessor :destination_id, :type, :active, :city, :province, :country, :country_code

      def initialize(info)
        info.each do |k, v|
          instance_variable_set("@" + k.to_s, v)
        end
      end

      class << self
        def find(info)
          params = {}
          [:city, :address].each do |dup|
            params[dup] = info[dup] if info[dup]
          end
          params[:destinationString] = info[:destination_string]
          if Configuration.cache? and Configuration.cache.cached?(:geoSearch, params)
            raw = Configuration.cache.get_query(:geoSearch, params)
          else
            url = url(:method => 'geoSearch', :params => params, :session => info[:session])
            raw = parse_response(url)
            handle_errors(raw)
          end
          parse(raw)
        end

        def parse(raw)
          [raw["LocationInfoResponse"]["LocationInfos"]["LocationInfo"]].flatten.map do |raw|
            Location.new(:province => raw["stateProvinceCode"], :destination_id => raw["destinationId"], :type => raw["type"], :city => raw["city"], :active => raw["active"], :code => raw["code"], :country => raw["country"], :country_code => raw["countryCode"]) 
          end
        end

        def handle_errors(info)
          key = info.keys.first
          if info[key] && info[key]["EanWsError"]
            message = info[key]["EanWsError"]["presentationMessage"]
          end
          raise EANException.new(message) if message
        end
      end
    end
  end
end
