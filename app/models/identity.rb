class Identity < ActiveRecord::Base
  has_one :authentication, :dependent => :destroy
  belongs_to :user
end
