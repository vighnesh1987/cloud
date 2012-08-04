class User < ActiveRecord::Base
  include UserHelper

  ############## ASSOCIATIONS ##########
  has_many :identities, :foreign_key => :user_id, :dependent => :destroy
  has_many :listings, :dependent => :destroy
  has_many :photos, :through => :listings
  has_many :ratings, :dependent => :destroy # as author
  has_many :storages, :dependent => :destroy

  ############## VALIDATIONS ###########
  validates :login,       :uniqueness => true, :presence => :true
  validates :first_name,  :presence => true
  validates :password,    :confirmation => true
  validates :password_confirmation,   :presence => true
  validates :email,       :confirmation => true, :uniqueness => true
  validates :email_confirmation,      :presence => true

  ############## HELPERS ###############
  def to_s
    "#{full_name}, trust:#{trust_score}, email:#{email}"
  end

  def full_name
    self.first_name + " " + self.last_name
  end

  ############## PASSWORDS #############
  class << self
    attr_accessor :RAND_RANGE 
  end
  @RAND_RANGE = 1000000 

  def set_salt(num)
    self.salt = num
  end

  def set_random_salt
    self.set_salt( Random.rand(User.RAND_RANGE) )
  end

  def compute_digest(passwd)
    require 'digest/sha1'
    pass_salt = passwd + self.salt.to_s
    Digest::SHA1.hexdigest pass_salt 
  end
  
  # getters, setters, validators for password
  def password
    @password
  end

  def password=(passwd)
    @password = passwd
    self.set_random_salt
    self.password_digest = self.compute_digest(passwd)
  end

  def password_valid?(passwd)
    self.compute_digest(passwd).eql? self.password_digest
  end

  # Make calls to Facebook Graph API here
  def updated_trust_score(seller)
    60 + self.trust_score
  end

	#return URL of the user's profile pic.
	def get_profile_picture_url
		identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
		return ApplicationController.fb_app[:graph][:query_root_url] + identity.uid + "/" + ApplicationController.fb_app[:graph][:query_mypic_suffix]		
	end

	#updates the facebook graph neighborhood of this user
	def update_facebook_graph
		#first get list of friends on facebook, add them as identities in the DB and in Neo4j (if they don't already exist), and 
		# create friend relationship with the user in Neo4j (again, if it doesn't already exist).
		identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
		fb_friends = fetch_facebook_friends()
		fb_friends.each do |friend_id|
			friend_identity = get_or_create_identity(ApplicationController.fb_app[:id], friend_id)
#			create_friend_relationship(identity, friend_identity)
#			create_mutual_facebook_friends(friend_identity)
		end
		puts "DEBUG: " + get_graph_identity(identity).rels(:outgoing,:friends).to_a.length.to_s + " Facebook friends of "+ identity.uid
		#next get list of users on facebook that this user has subscribed to, add them as identities in the DB and in Neo4j (if they don't already exist), and 
    # create subscribedto relationship with the user in Neo4j (again, if it doesn't already exist).
		fb_subscribedto = fetch_facebook_subscribedto()
		# Only deal with subscribedto that are not friends.
 		fb_subscribedto = fb_subscribedto - fb_friends
		fb_subscribedto.each do |subto_id|
			subto_identity = get_or_create_identity(ApplicationController.fb_app[:id], subto_id)
#			create_subscribedto_relationship(identity, subto_id)
#			create_mutual_facebook_friends(subto_identity)
		end
		#next get list of users on facebook that have subscribed to this user, add them as identities in the DB and in Neo4j (if they don't already exist), and 
    # create subscribedto relationship with the user in Neo4j (again, if it doesn't already exist).
		fb_subscribers = fetch_facebook_subscribers()
		# Only deal with subscribers that are not friends.
		fb_subscribers = fb_subscribers - fb_friends
		fb_subscribers.each do |sub_id|
			sub_identity = get_or_create_identity(ApplicationController.fb_app[:id], sub_id)
#			create_subscribedto_relationship(sub_identity, identity)
#			create_mutual_facebook_friends(sub_identity)
		end
		#next get list of users on facebook that have posted on or been mentioned on or commented on or liked this user's wall, add them as identities in the DB 
		#and in Neo4j (if they don't already exist), and find mutual friends with each such poster, and store those relationships.
		fb_wall_posters = fetch_facebook_wall_posters()
		# Only deal with posters that are neither friends or subscribers nor subscribedto.
		fb_wall_posters = fb_wall_posters - fb_friends - fb_subscribedto - fb_subscribers
		fb_wall_posters.each do |poster_id|
			poster_identity = get_or_create_identity(ApplicationController.fb_app[:id], poster_id)
#			create_mutual_facebook_friends(poster_identity)		
		end
		return nil
	end

	#return an array of facebook friend IDs.
	def fetch_facebook_friends
		return fetch_facebook_friends_or_subscribers_or_subscribedto("friends")
	end

	#return an array of facebook IDs that subscribe to this user	
	def fetch_facebook_subscribers
		return fetch_facebook_friends_or_subscribers_or_subscribedto("subscribers")
	end

	#return an array of facebook IDs that this user subscribes to
	def fetch_facebook_subscribedto
		return fetch_facebook_friends_or_subscribers_or_subscribedto("subscribedto")
	end

	#return an array of facebook IDs (friends, subscribers or subscribedto) depending on the argument passed in.
	#this method does all the heavy lifting.
	def fetch_facebook_friends_or_subscribers_or_subscribedto (type)
    identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
		if type == "friends"
			graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_friends_suffix], {:access_token =>identity.authentication.token} )
		elsif type == "subscribers"
			graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_subscribers_suffix], {:access_token =>identity.authentication.token} )
		elsif type == "subscribedto"
			graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_subscribedto_suffix], {:access_token =>identity.authentication.token} )
		else
			graph_url_string = nil;
			alert_log("Invalid type: Cannot fetch facebook connections of type: "+type)			
			not_found
		end
		return fetch_facebook_list_data(graph_url_string)
	end

	#return an array of user IDs that are mutual friends of this user and the other_identity.	
	def fetch_mutual_facebook_friends(other_identity)
		fb_list = Array.new
		my_identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
		# if other_identity is not a facebook identity, raise alarm.
		if other_identity.provider_id != ApplicationController.fb_app[:id]
			alert_log("Trying to get mutual facebook friends with a non-facebook identity: (#{other_identity.provider_id},#{other_identity.uid})" )
			not_found
		end
		# This URL is of the form: https://graph.facebook.com/me/mutualfriends/123456789?accesstoken=....., where 123456789 is other_identity.uid
		graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_mutualfriends_suffix] + "/" + other_identity.uid, {:access_token => my_identity.authentication.token} )
		return fetch_facebook_list_data(graph_url_string)
	end

	#fetches mutual friend relationships between this user and the other_identity and creates those friend relationships
	# if they don't exist already. Uses get_mutual_facebook_friends() method to fetch mutual friends using facebook API.  
	def create_mutual_facebook_friends(other_identity)
		# get this user's identity
		identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
		fb_mutual_friends = fetch_mutual_facebook_friends(other_identity)
    fb_mutual_friends.each do |mutualfriend_id|
			# get or create an identity for each mutual friend
			mutual_friend_identity = get_or_create_identity(ApplicationController.fb_app[:id], mutual_friend_id)
#      create_friend_relationship(identity, mutual_friend_identity)
#      create_friend_relationship(mutual_friend_identity, other_identity)
    end
	end

	#return an array of user IDs that have appeared (e.g., posted, mentioned, liked)  on this user's wall.
	def fetch_facebook_wall_posters
		fb_wall_posters = Array.new
		identity = self.identities.find_by_provider_id(ApplicationController.fb_app[:id])
    graph_url_string = getURL( ApplicationController.fb_app[:graph][:query_root_url] + ApplicationController.fb_app[:graph][:query_feed_suffix], {:access_token => identity.authentication.token} )
		while !graph_url_string.nil?
	    puts "REQUESTING: "+graph_url_string
      resp = https_get_helper(graph_url_string)      
			resp_hash = JSON.parse(resp, :symbolize_names => true)
			# add fetched list of friends to the fb_friends array
			if !resp_hash[:data].nil?
				resp_hash[:data].each do |wall_post| 
					puts wall_post.to_s
					# get ID of the user who created the wall post.
					if !wall_post[:from].nil?
						fb_wall_posters << wall_post[:from][:id]
					end
					# get IDs of all users, if any, who the wall post was addressed to. 
					if !wall_post[:to].nil? and !wall_post[:to][:data].nil?
						wall_post[:to][:data].each { |to_user| fb_wall_posters << to_user[:id] }
					end
					# get IDs of all users who liked the wall post
					if !wall_post[:likes].nil? and !wall_post[:likes][:data].nil?
						wall_post[:likes][:data].each { |likes_user| fb_wall_posters << likes_user[:id] }
					end
					# get IDs of all users who commented on the wall post.
					if !wall_post[:comments].nil? and !wall_post[:comments][:data].nil?
						wall_post[:comments][:data].each do |comment| 
							fb_wall_posters << comment[:from][:id]
							if comment[:message_tags].nil?
								next
							end
							# get IDs of all users who were tagged in the comments of the wall post.
							comment[:message_tags].each do |comment_msg_tag|
								if comment_msg_tag[:type] == "user"
									fb_wall_posters << comment_msg_tag[:id]
								end
							end
						end
					end
					# get IDs of all users who were tagged in the wall post.
					if !wall_post[:message_tags].nil?
						wall_post[:message_tags].each_pair do |offset, data|
							data.each do |tag_info| 
								if tag_info[:type] == "user" 
									fb_wall_posters << tag_info[:id] 
								end
							end
						end
					end
				end #end-resp_hash[:data].each do |wall_post|
			end # end-if !resp_hash[:data].nil?
      if resp_hash[:paging].nil?
				graph_url_string = nil;
			else
				graph_url_string = resp_hash[:paging][:next]
    	end  
		end
		puts fb_wall_posters.uniq.to_s
		return fb_wall_posters.uniq
	end

end
