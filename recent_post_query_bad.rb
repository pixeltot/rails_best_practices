class PostController < ApplicationController
	def index
		@posts = Post.where('published = ? AND published_on > ?', true, 2.days.ago)
	end
end

# query that returns the most recent published post
# and assigns it to the '@posts' instance variable

# Some problems with this code:

	# 1. Exposes implementation details (which breaks encapsulation. should be placed in a model)
	# 2. Produces unecessary duplication (if you wanted to fetch the most recent posts you would have to re-write this code over and over again)
	# 3. Complicates writing tests.