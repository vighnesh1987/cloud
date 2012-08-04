class Listing < ActiveRecord::Base
  ############## ASSOCIATIONS ##########
  belongs_to :user
  has_many   :photos,  :dependent => :destroy
  has_many   :ratings, :dependent => :destroy
  
  ############## VALIDATIONS ###########
  validates :title, :presence => true
  validates :category, :presence => true
  validates :body,  :presence => true
  validates :url,   :presence => true

  ############ HELPERS ################
  def to_s
    "#{randomized_id} belongs to seller:\n #{user} "
  end

end

