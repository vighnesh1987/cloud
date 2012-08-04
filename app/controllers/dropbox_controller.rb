require 'dropbox_sdk'

# This is an example of a Rails 3 controller that authorizes an application
# and then uploads a file to the user's Dropbox.

# You must set these
APP_KEY = "wcuk2fg3iguw8uo"
APP_SECRET = "lijv5ogs0vi60mu"
ACCESS_TYPE = :dropbox #The two valid values here are :app_folder and :dropbox
                          #The default is :app_folder, but your application might be
                          #set to have full :dropbox access.  Check your app at
                          #https://www.dropbox.com/developers/apps


# Examples routes for config/routes.rb  (Rails 3)
#match 'db/authorize', :controller => 'db', :action => 'authorize'
#match 'db/upload', :controller => 'db', :action => 'upload'

class DropboxController < ApplicationController
    @@DROPBOX_LOGO = "http://dl.dropbox.com/sh/sf6whlu5dae4869/F0GHIVNrvB/Dropbox%20Logos/White/esuslogo101409%20white.GIF"
    class << self
      def get_logo
        @@DROPBOX_LOGO
      end
    end

    attr_accessor :dbsession

    def authorize
      @dbsession = DropboxSession.new(APP_KEY, APP_SECRET)
      @dbsession.get_request_token
      authorize_url = @dbsession.get_authorize_url(url_for :controller => :dropbox, :action => :callback)
      # Make the user sign in and authorize this token
      session[:dbsession] = @dbsession
      redirect_to authorize_url
      #puts "Please visit that website and hit 'Allow', then hit Enter here."
      #gets

      ## This will fail if the user didn't visit the above URL and hit 'Allow'
      #session.get_access_token

      #client = DropboxClient.new(session, ACCESS_TYPE)
      #puts "linked account:", client.account_info().inspect
    end
  
    def callback
      @dbsession = session[:dbsession]
      token = @dbsession.get_access_token
      @client = DropboxClient.new(@dbsession, ACCESS_TYPE)

      session[:dbclient] = @client
      user = User.find(session[:userid])
      if user.storages.where("provider = ?", 'dropbox').count == 0
        user_hash = {:uid => params[:uid], :auth_token => token, :user_id => user.id, :provider => 'dropbox'}
        storage = Storage.new(user_hash)
        puts user_hash
        storage.save
      end
      redirect_to :root
    end

    def get_name(path)
      require 'pathname'
      Pathname.new(path).basename.to_s
    end

    def get_meta
      path = params[:path]
      @dbclient = session[:dbclient]
      metainfo = @dbclient.metadata(path)
      file_list = metainfo["contents"]
      ret_list = []
      file_list.each do |f|
        ret_list << {:name => get_name(f["path"]), :path => f["path"], :is_dir => f["is_dir"]}
      end
      render :partial => "/shared/file_list", :locals => {:list => ret_list}
    end

end
