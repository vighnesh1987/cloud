class ListingController < ApplicationController
  include ListingHelper

  # Used for creating new post
  def new
    @user = getCurrentUser("create new listing")
  end

  def post_new
    @user = getCurrentUser("create new listing")
    # Saves the listing entry in the DB
    @listing = Listing.new(params[:listing])
    @listing.url = "/path/to/craigslist/post" 
    @listing.user_id = @user.id
    rand_string = get_random_trust_code 
    @listing.randomized_id = rand_string

    if @listing.valid? then
      @listing.save
      #
      # Here we send HTML request to craigslist
      # 
      notifySuccess(@listing, "created a new listing")
    else 
      notifyFailure(@listing, "creating a new listing")
    end
  end

  ### Used for generating new trust-url and handles clicks on it
  def generate_trust_url
    @user = getCurrentUser("generate a new trust-url")
    rand_string = get_random_trust_code
    trust_url = "http://" + self.class.hostname + "/trust/" + rand_string
    puts "#### HERE ####", root_url
    @listing = Listing.new({:user_id => @user.id,
                            :randomized_id => rand_string,
                            :title => "Temp title",
                            :category => "Temp category",
                            :body => "Temp body",
                            :url => "temp/url",
                            :embedded_trust_url => trust_url})
    if @listing.valid? then
      @listing.save
      #flash[:success] = "Here's your new trust_url\n" + trust_url
      render :partial => "listing/inline_tpot_url"
    else 
      notifyFailure(@listing, "generating a new trust_url")
    end
  end

  # This gets called if someone clicks on a tpot link on Craigslist,
  # which was generated using generate_trust_url
  def click_trust_url
    puts "=========== click_trust_url ======="
    @listing = Listing.find_by_randomized_id(params[:id])
    @seller = User.find(@listing.user_id)
    @listing_code = params[:id]
    @trust_score = @seller.trust_score
    @buyer = nil


    # Check if the user is already logged in and update trust score if so
    if !session[:userid].nil? and User.exists?(:id => session[:userid]) then
      puts "============ User already logged in ========="
      @buyer = User.find(session[:userid])
      @trust_score = @seller.updated_trust_score(@buyer)

      # Check if buyer has already rated the transaction
      # Should have count = 0 or 1
      @rating = @listing.ratings.where("rater_id = ?", @buyer.id)
      puts "=========== Found #{@rating}"
      @allow_to_rate = (@rating.count == 0)
      if @rating.count > 1 then 
        alert_log(@listing.to_s + "has too many ratings from buyer" + @buyer.to_s)
      end
    end
  end


  # Renders a form that allows searching for a listing by it's randomized id
  def search_by_randomized_id

  end


  def view
    @listing = Listing.find(params[:id])
    if @listing.nil? then
      flash[:failure] = "There is no such listing"
      redirect_to :controller => :user, :action => :home
    end
  end

  def delete
  end

end

