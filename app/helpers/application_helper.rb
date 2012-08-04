module ApplicationHelper
	# Utility methods defined as class methods in the ApplicationController.
  def getURL(base, arg_hash)
    require 'cgi'
    arg_string = arg_hash.collect { |k,v| "#{k.to_s}=#{CGI::escape(v.to_s)}" }.join('&')
    url = base + "?" + arg_string 
  end

	def https_get_helper(url_string)
    require 'net/https'
    url = URI.parse(url_string)
    http = Net::HTTP.new url.host, url.port
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    http.use_ssl = true
    http.start do |agent|
      @rcvd_response = agent.get(url_string).read_body
    end
    return @rcvd_response
  end

  def alert_log(str)
    #flash[:failure] = str
    puts "*************************** ALERT STARTS *************************"
    puts str
    puts "*************************** ALERT ENDS ***************************"
  end

  # Helper function to display 404
  def not_found
      raise ActionController::RoutingError.new('Not Found')
  end
end

