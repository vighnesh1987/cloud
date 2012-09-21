class UserController < ApplicationController
  include UserHelper 
  include DropboxHelper

  # security_code needs to be passed alongwith the FB login request
  #@security_code = ""

  #class << self
    #attr_accessor :security_code
  #end

  ######### LOGIN ##################
  def login
    if params[:provider] == "facebook" then
      role = params[:role].to_sym
      session[:fb_security_code] = SecureRandom.hex

      case role
      when :buyer
        extra = {:listing_randomized_id => params[:code]}
      when :seller
        extra = {}
      end
      state_json = fb_create_state(session[:fb_security_code], extra)
      fb_auth_redir_arg = { :client_id => ApplicationController.fb_app[:app_id], 
                            :redirect_uri => ApplicationController.fb_app[:auth_redir][role], 
                            :state => state_json,
                            :cancel_url => ApplicationController.fb_app[:cancel_url], 
                            :scope => ApplicationController.fb_app[:auth_redir][:scope] 
                          }
      fb_login_redir_url = getURL(ApplicationController.fb_app[:auth_redir][:base_url], fb_auth_redir_arg)
      redirect_to fb_login_redir_url
    end
  end

  def post_login
    @uname = params[:uname]
    @pwd= params[:pwd]
    @user = User.find_by_login(params[:uname])
    if @user.nil?
      flash[:failure] = "Username does not exist."
      redirect_to :action => :login
    else      # username exists
      if @user.password_valid?(@pwd)
        session[:userid] = @user.id
        flash[:success] = "Welcome " + @user.full_name + "!"
        redirect_to :action => :home
      else    # password mismatch
        flash[:failure] = "That username/password combination does not exist."
        redirect_to :back
      end
    end
  end

  def logout
    session[:userid] = nil
    flash[:success] = "You've been successfully logged out."
    redirect_to :action => :login
  end

  ######### HOME #################
  def home
    if !session[:userid].nil? then
      uid = session[:userid]
      redirect_to :action => :login unless User.exists?(:id => uid)
      @user = User.find(uid)
      @dropbox_file_list = get_dropbox_file_list("/")
      @skydrive_file_list = ["Skydrive stuff", "Done"]
    else
      redirect_to :action => :login
    end
  end

  ######## FB AUTH ##############
  def fb_buyer_callback
    auth_result_state, @buyer = fb_authorize(:buyer)
    not_found if auth_result_state == :auth_sec_failure

    security_code, extra = fb_parse_state(params[:state])
    @listing = Listing.find_by_randomized_id(extra[:listing_randomized_id])

    case auth_result_state
    when :auth_success
      @trust_score = @buyer.updated_trust_score(@listing.user)
      @rating = @listing.ratings.where("rater_id = ?", @buyer.id)
      @allow_to_rate = (@rating.count == 0)
      render "listing/click_trust_url"
    when :auth_failure
      redirect_to :controller => :listing, :action => :click_trust_url, :id => @listing.randomized_id 
    else not_found
    end
  end

  def fb_seller_callback
    auth_result_state, @seller = fb_authorize(:seller)
    not_found if auth_result_state == :auth_sec_failure

    case auth_result_state
    when :auth_success
      redirect_to :action => :home
    when :auth_failure
      redirect_to :action => :register
    else not_found
    end
  end

  def fb_reg_callback
    # In case we end up using the FB registration form  
  end

  ######### REGISTER #############
  def register
    if !session[:userid].nil?
      uid = session[:userid]
      flash[:failure] = "You are logged in as '" + User.find(uid).login + 
                       "'. Logout and then try to register."
      redirect_to :controller => :pics, :action => :user, :id => uid 
    else
      @user = User.new
    end
  end

  def post_register
    user_info = params[:user]
    user_hash = {:first_name => user_info[:first_name].capitalize, 
                 :last_name => user_info[:last_name].capitalize, 
                 :trust_score => 0,
                 :login => user_info[:login].downcase,
                 :email => user_info[:email],
                 :email_confirmation => user_info[:email_confirmation],
                 :password => user_info[:password],
                 :password_confirmation => user_info[:password_confirmation]}
      status, user = try_store_new_user(user_hash)
      case status
      when :user_saved
        session[:userid] = user.id
        redirect_to :action => :home
      else
        redirect_to :action => :register
      end
  end

end


