# ALL BUSINESS LOGIC SHOULD GO IN THE MODELS
#-------------------------------------------

# in this example we call @item.publish
# '.publish' method comes from the logic inside of the model
# its saying if an Item is not approved or if the user is 'bobby' then we return false
# this is called a guard clause and it simplifies code making it easier to read
# if pre-conditions are good, it sets the published_on property and save the object
# this is all encapsulated in our model
# now we can use the '.publish' method on an @item object in our controller

# app\models\item.rb
class Item < ActiveRecord::Base
	belongs_to :user

	def publish
		if !approved? || user == 'bobby'
			return false
		end
	self.published_on = Time.now
	self.save
	end
end

#app\controllers\items_controller.rb
class ItemsController < ApplicationController
	def publish
		if @item.publish # <===========3 check out this publish method =) 
			flash[:notice] =  "Your item published!"
		else
			flash[:notice] = "There was an error"
		end
	redirect_to @item
	end
end


