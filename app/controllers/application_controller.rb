class ApplicationController < ActionController::Base
  protect_from_forgery

  # Turn off layout rendering for AJAX
  layout proc{ |c| c.request.xhr? ? false : "application" }


  # App information stored as class constant
  @@hostname ={ :development => "local.cloudgator.herokuapp.com:3000",
                :production  => "cloudgator.herokuapp.com",
                :test        => "local.cloudgator.herokuapp.com:3000"
              }
  def self.hostname
    @@hostname[Rails.env.to_sym]
  end

  @@FB_APP = {  :name => "facebook", 
                :id   => 111,         # for storing in provider_id column
                :app_id => "270931059687131", 
                :app_secret =>  "c912f265d7694dc5347de7dbc05d06c8", 
                :cancel_url => "http://" + self.hostname, 
                :auth_redir =>  { :base_url => "https://www.facebook.com/dialog/oauth", 
                                  :seller => "http://" + self.hostname + "/user/fb_seller_callback",
                                  :buyer => "http://" + self.hostname + "/user/fb_buyer_callback",
                                  :scope => "email, user_education_history, user_work_history, user_hometown, user_location, read_stream, publish_actions" 
                                },
                :graph  =>  { :access_token_url => "https://graph.facebook.com/oauth/access_token",
                              :query_root_url => "https://graph.facebook.com/",
														  :query_me_suffix => "me", 
														  :query_mypic_suffix => "picture",								
															:query_friends_suffix => "me/friends",
															:query_subscribers_suffix => "me/subscribers",
															:query_subscribedto_suffix => "me/subscribedto",
															:query_feed_suffix => "me/feed",
															:query_mutualfriends_suffix => "me/mutualfriends",
                            }
             }
  def self.fb_app
    @@FB_APP
  end

end



