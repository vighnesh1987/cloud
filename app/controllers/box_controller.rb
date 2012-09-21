require "box-api"

APP_KEY = "s2xoy3gxejr9iqc9ovi448sshmt0fk7s"

class BoxController < ApplicationController

  @@BOX_LOGO = "http://dl.dropbox.com/sh/sf6whlu5dae4869/F0GHIVNrvB/Dropbox%20Logos/White/esuslogo101409%20white.GIF"

    class << self
      def get_logo
        @@BOX_LOGO
      end
    end

    def authorize
      if session[:boxsession].nil?
        account = Box::Account.new(APP_KEY)

        # read any auth tokens if they are saved, so we don't have to re-authenticate on Box
        auth_token = session[:box_auth_token]

        # try to authorize using the auth token, or request a new one if not
        account.authorize(:auth_token => auth_token) do |auth_url|
          # this block is called if the auth_token is invalid or missing
          redirect_to auth_url
        end
      else
        redirect_to :action => :callback
      end
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
      session[:provider_tab] = :dropbox_tab
      redirect_to :root
    end

end

