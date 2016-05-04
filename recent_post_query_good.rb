# Extracting Queries
#--------------------

# app\controllers\posts_controller.rb
class PostsController < ApplicationController
	def index
		@posts = Post.recent #calling the recent method from our class method in the post model
	end
end

# Query implemented as class method, the model encapsulated details about the query
# app\models\post.rb
class Post < ActiveRecord
 def self.recent
 	where('published = ? AND published_on > ?', true, 2.days.ago)
 end

end

