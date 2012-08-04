class Rating < ActiveRecord::Base
  belongs_to :listing
  belongs_to :user

  # Validations
  #validates :stars,   :presence => :true
  #validates :rater_comment, :presence => :true

end
