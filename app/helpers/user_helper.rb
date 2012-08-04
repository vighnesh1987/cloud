module UserHelper
  include ApplicationHelper

	# This method returns an existing identity in the DB, or creates one if it doesn't exist already.
	# Moreover, it is responsible for maintaining referential integrity (i.e., 1:1 mapping) between 
	# the identities in the DB and the identities in Neo4j.   
#  def get_or_create_identity(provider_id, uid)
#    found_identity = Identity.where("provider_id = ? and uid = ?", provider_id, uid)
#    case found_identity.length
#    when 0  # create identity and return it
#      created_identity = Identity.new(:provider_id => provider_id, :uid => uid)
			# Raise an alarm if there exists a GraphIdentity for this (provider_id,uid)
#			if !get_graph_identity(created_identity).nil?
#          alert_log("Graph identity already exists for a new identity: uid #{uid} and provider_id #{provider_id}")
#					not_found
#      end
#      if created_identity.save
#				if !create_graph_identity(created_identity).nil?
#        	return created_identity
#				else
#					alert_log("Saved identity for uid #{uid} and provider_id #{provider_id}, but failed to save GraphIdentity")
#					not_found
#				end
#      else
#        alert_log("Failed to save identity for uid #{uid} and provider_id #{provider_id}")
#        not_found
#      end
#    when 1  # return Identity
			# Raise an alarm if there does NOT exist a GraphIdentity for this (provider,uid)
#			if get_graph_identity(found_identity.first).nil?
#          alert_log("Graph identity does not exist for an existing identity: uid #{uid} and provider_id #{provider_id}")
#          not_found
#      end
#      return found_identity.first
#    else  # report error
#      alert_log("Multiple identities for same uid #{uid} and provider_id #{provider_id}")
#      not_found
#    end
#  end

	def get_graph_identity(identity)
		found_identity = GraphIdentity.all(:provider_id => identity.provider_id, :uid => identity.uid)
    case found_identity.size
    when 0  # GraphIdentity does not exist; return nil.
			return nil
    when 1  # GraphIdentity exists;  return it.
      return found_identity.first
    else  # report error
      alert_log("Neo4j: Multiple identities for same uid #{identity.uid} and provider_id #{identity.provider_id}")
      not_found
    end
	end 

	# TODO: This method should be made private so that only the get_or_create_identity() method can call it.
	def create_graph_identity(identity)
		created_identity = GraphIdentity.create(:provider_id => identity.provider_id, :uid => identity.uid)
    if created_identity.save
	    return created_identity
    else
      alert_log("Neo4j: Failed to save identity for uid #{identity.uid} and provider_id #{identity.provider_id}")
      not_found
    end
	end

	# Creates relationships id1 ---friend---> id2 and id2 ---friend---> id1 in Neo4j if they don't already exist.
	def create_friend_relationship(id1, id2)
    identity1 = get_graph_identity(id1)
    identity2 = get_graph_identity(id2)
		friendships12 = nil
		friendships21 = nil
    rels1 = identity1.rels(:outgoing,:friends)
    rels2 = identity2.rels(:outgoing,:friends)
		# The following logic ensures that one of (a) or (b) is true:
		# (a) There is exactly one friend reltaionship id1 ---> id2, and exactly one friend relationship id2 ---> id1
		# (b) There is no friend relationship from id1 to id2 and there is none from id2 to id1.
		# If (a) is true, the method does nothing. If (b) is true, it creates a friend relationship id1 ---> id2, and another id2 ---> id1.
		# If neither (a) nor (b) is true, the method raises an alarm.
    if !rels1.nil? and rels1.count > 0
      puts "DEBUG: "+rels1.count.to_s
      friendships12 = rels1.to_other(identity2)
    end
    if !rels2.nil? and rels2.count > 0
      friendships21 = rels2.to_other(identity1)
    end
    if friendships12.nil? and friendships21.nil?
      puts "DEBUG: Adding friendship between ("+identity1.provider_id.to_s+","+identity1.uid.to_s+" and "+identity2.provider_id.to_s+","+identity2.uid.to_s+")"
      identity1.outgoing(:friends) << identity2
      identity2.outgoing(:friends) << identity1
    elsif !friendships12.nil? and !friendships21.nil?
      if friendships12.count != friendships21.count
        alert_log("Asymmetric friendship betweeen (#{identity1.provider_id.to_s},#{identity1.uid.to_s}) and (#{identity2.provider_id.to_s},#{identity2.uid.to_s})")
        not_found
      elsif friendships12.count > 1
        alert_log("More than one friendship between (#{identity1.provider_id.to_s},#{identity1.uid.to_s}) and (#{identity2.provider_id.to_s},#{identity2.uid.to_s})")
        not_found
			elsif friendships12.count == 1
				# no op, relationship already exists.
      elsif friendships12.count == 0
        puts "DEBUG: Adding friendship between ("+identity1.provider_id.to_s+","+identity1.uid.to_s+" and "+identity2.provider_id.to_s+","+identity2.uid.to_s+")"
        identity1.outgoing(:friends) << identity2
        identity2.outgoing(:friends) << identity1
      end
    else
      # one of friendships12 and friendships21 is nil while the other isn't. ERROR
      alert_log("Only one of the friendship counts is 0 between (#{identity1.provider_id},#{identity1.uid}) and (#{identity2.provider_id},#{identity2.uid})")
      not_found
    end
  end

	# Creates a relationship id1 ---subscribedto---> id2 if one doesn't already exist.
	def create_subscribedto_relationship(id1, id2)		
		identity1 = get_graph_identity(id1)
    identity2 = get_graph_identity(id2)
    subscribedto12 = nil
    rels = identity1.rels(:outgoing,:subscribedto)
		if !rels.nil? and rels.count > 0
			subscribedto12 = rels.to_other(identity2)
		end
		if subscribedto12.nil? or subscribedto12.count == 0
			identity1.outgoing(:subscribedto) << identity2
		elsif subscribedto12.count == 1
			# no op, relationship already exists.
		else
			alert_log("More than one subscribedto relationships exist between (#{identity1.provider_id},#{identity1.uid}) and (#{identity2.provider_id},#{identity2.uid})")
			not_found
		end
	end

# ALL METHODS ABOVE THIS LINE INVOLVE NEO4J SPECIFIC CODE AND ARE DEFUNCT UNTIL WE USE NEO4J.


	# Creates a new identity or returns one if one already exists. An identity is a (provider_id, uid) pair. 
	def get_or_create_identity(provider_id, uid)
    found_identity = Identity.where("provider_id = ? and uid = ?", provider_id, uid)
    case found_identity.length
    when 0  # create identity and return it
      created_identity = Identity.new(:provider_id => provider_id, :uid => uid)
      if created_identity.save
        #if !create_graph_identity(created_identity).nil?
          return created_identity
        #else
          #alert_log("Saved identity for uid #{uid} and provider_id #{provider_id}, but failed to save GraphIdentity")
          #not_found
        #end
      else
        alert_log("Failed to save identity for uid #{uid} and provider_id #{provider_id}")
        not_found
      end
    when 1  # return Identity
      return found_identity.first
    else  # report error
      alert_log("Multiple identities for same uid #{uid} and provider_id #{provider_id}")
      not_found
    end
  end

  # Get or create a connection - presently asymmetric
  def get_or_create_connection(id1, id2, type)
    found_conn = Connection.where("id1 = ? and id2 = ? and link_type = ?", id1, id2, type)
    case found_conn.length
    when 0
      conn = Connection.new(:id1 => id1, :id2 => id2, :link_type => type)
      if conn.save
        return conn
      else
        alert_log("Failed to create a connection from #{id1} and #{id2} of type = #{type}")
        return nil
      end
    when 1
      return found_conn.first
    else
      alert_log("Found multiple entries for same connection attributes!")
    end
  end

  # Returns status and user
  def try_store_new_user(user_hash)
    user = User.new(user_hash)

    if user.valid? 
      if user.save
        flash[:success] = "Registration successful! Welcome " + user.first_name + "!"
        return :user_saved, user
      else  # not saved
        flash[:failure] = "Unexpected error while saving. Try again."
        return :unexpected_error, user
      end
    else      # user validation failed
      flash[:failure] = ["Unsuccessful! Fix the following errors."] 
      user.errors.full_messages.each do |msg| 
        flash[:failure] << (msg + ".")
      end
      return :user_validation_failed, user
    end
  end

  ############# Facebook Auth helper functions ############
  # extra is a hash of state info that needs to be maintained
  def fb_create_state(security_code, extra)
    state_passed =  { 
                      :security_code => security_code,
                      :extra => extra
                    }
    return ActiveSupport::JSON.encode(state_passed)
  end

  def fb_parse_state(state_json)
    state_passed = ActiveSupport::JSON.decode(state_json).symbolize_keys
    return state_passed[:security_code], state_passed[:extra].with_indifferent_access
  end

  def fb_callback_security_pass
    # Check for FB callback failure
    if params[:error_reason] then
      # Some error
      flash[:failure] = params[:error_description]
      return false 
    end
    # Check for forgery attempts
    security_code, extra = fb_parse_state(params[:state])
    if security_code != session[:fb_security_code] then 
      flash[:failure] = "Forgery attempt. Authorities have been informed.\n"
      return false
    end
    session[:fb_security_code] = nil 
    return true
  end

  def get_login_for_fb_user(resp_hash)
    #if resp_hash[:username].nil?
      return resp_hash[:first_name].to_s.downcase + resp_hash[:id].to_s
    #else
      #return resp_hash[:username].to_s.downcase,
    #end
  end

  def fb_authorize(role)
    return :auth_sec_failure, nil unless fb_callback_security_pass

    require 'net/https'
    require 'cgi'
    require 'socket'
    require 'json'
    # Now use the code returned to get an access token
    arg_hash =  { "client_id"=> ApplicationController.fb_app[:app_id], 
                  "redirect_uri" => ApplicationController.fb_app[:auth_redir][role], 
                  "client_secret"=> ApplicationController.fb_app[:app_secret], 
                  "code"=>params[:code] 
                }
    url_string = getURL( ApplicationController.fb_app[:graph][:access_token_url], arg_hash )
    resp = https_get_helper(url_string)

    # Use access token to make requests
    mat = resp.scan(/access_token=([^&]+)&expires=(\d+)/)
    token, exp_time = mat[0]

    # Query the Facebook Graph API with the access_token
		graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_me_suffix], {:access_token => token} )
    resp = https_get_helper(graph_url_string)
    puts "-------------DEBUG-------------", resp

    resp_hash = ActiveSupport::JSON.decode(resp).symbolize_keys
    identity = get_or_create_identity(ApplicationController.fb_app[:id], resp_hash[:id].to_s)
    found_auth = identity.authentication

    init_passwd = SecureRandom.hex    # Creates 32 length by default
    user_hash = { :first_name => resp_hash[:first_name].to_s.capitalize, 
                  :last_name => resp_hash[:last_name].to_s.capitalize, 
                  :trust_score => 42,
                  :login => get_login_for_fb_user(resp_hash),
                  :email => resp_hash[:email],
                  :email_confirmation => resp_hash[:email],
                  :password => init_passwd, 
                  :password_confirmation => init_passwd
                }

    if found_auth.nil? then  # Authentication and user need to be created
      puts "-------------Creating new auth------------", user_hash
      status, user = try_store_new_user(user_hash)
      case status
      when :user_saved
        puts "-------------User saved - creating auth-----------"
        identity.create_authentication(:token => token)
        puts "-------------Associating saved user with identity-----"
        identity.user = user
        identity.save
        #user.authentications.create(:auth_provider => ApplicationController.fb_app[:name], :auth_id => resp_hash[:id].to_s, :token => token)
        flash[:success] += " Your username is " + user_hash[:login] + " and password is " + user_hash[:password] 
        session[:userid] = user.id
        auth_result_state = :auth_success
      else # :user_validation_failed, :unexpected_error
        alert_log("Couldn't save user!")
        auth_result_state = :auth_failure
      end
    else  # Authentication already exists 
      puts "-------------Auth exists - log in---------"
      # Save new token
      found_auth.update_attributes({:token => token})

      user = identity.user                 ########## Brittle code
      if user.nil?
        alert_log("Auth exists, but user doesn't.") 
        not_found
      end
      session[:userid] = user.id 
      flash[:success] = "Welcome " + user.full_name + "!"
      auth_result_state = :auth_success
    #else                   # Multiple auth entries in the table - raise error
      #puts "----Found multiple auth entries--"
      #flash[:failure] = "Error: multiple auth entries. Inform admins."
      #redirect_to :root
    end                           # User needs to be created - end
    return auth_result_state, user
  end

	# returns an array of facebok list data (e.g. friends, mutual friends, subscribed to, subscribers) found at url
	# makes followup requests to get paginated data.  
	def fetch_facebook_list_data(url)
		fb_list = Array.new
		while !url.nil?
      puts "REQUESTING: "+url
      resp = https_get_helper(url)
      resp_hash = JSON.parse(resp, :symbolize_names => true)
      # add fetched list of records to the fb_list array
      if !resp_hash[:data].nil?
        resp_hash[:data].each { |record| fb_list << record[:id] }
        if resp_hash[:paging].nil?
          url = nil;
        else
          url = resp_hash[:paging][:next]
        end
      end
    end # end-while
    return fb_list.uniq
	end

end

