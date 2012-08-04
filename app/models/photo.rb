class Photo < ActiveRecord::Base
  ############## ASSOCIATIONS ##########
  belongs_to :listing

  ############## VALIDATIONS ###########
  validates :listing_id,  :presence => true
  validates :file_name,   :presence => true

end
