module ListingHelper
  include ApplicationHelper

  ##### HELPERS #######
  def getCurrentUser(actionmsg)
    # Checks if a user is logged in, redirects to login page, if not true
    # returns user object if true
    # actionmsg is appended to the flash error string
    if session[:userid].nil?
      flash[:failure] = "You need to be logged in to " + actionmsg
      redirect_to :controller => :user, :action => :login 
    else
      user = User.find(session[:userid])
    end
    user
  end

  def notifyFailure(obj, actionmsg)
      flash[:failure] = ["Unsuccessful at " + actionmsg] 
      obj.errors.full_messages.each do |msg| 
        flash[:failure] << (msg + ".")
      end
      redirect_to :back
  end

  def notifySuccess(obj, actionmsg)
    flash[:success] = "You successfully " + actionmsg
    redirect_to :action => :view, :id => obj.id
  end

  def get_random_trust_code
    SecureRandom.urlsafe_base64(10)
  end
end

