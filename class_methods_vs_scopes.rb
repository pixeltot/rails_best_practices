# CLASS METHODS VS SCOPE

# here is a class method that gets an authors recent post
# this example also illustrates why scope is a better option
# the class method can be verbose while the scope method is much more slim

# app\models\post.rb
class Post < ActiveRecord
	def self.by_author(author)
		where(author: author)
	end

	def self.recent
		where('published_on > ?', 2.days.ago)
	end
end

# these two methods 'by_author' and 'recent' can be chained together like:
	Post.by_author.recent
# but what if the author happends to be nil?
# if a user goes to a search bar and submits the form without typing anything in
# hoping to get all the recent posts from all authors
# the query that this would generate would be all posts where the author is null
# doing the opposite of what we would want!

# app\models\post.rb
class Post < ActiveRecord
	def self.by_author(author)
		where(author: author) if author.present?
	end

	def self.recent
		where('published_on > ?', 2.days.ago)
	end
end

# so...we add 'author.present?' otherwise it will return nil (or null, same thing)
# but then we call
Post.by_author.recent
# this will cause a NoMethodError: undefined method 'recent' for nil:class
# to fix this error we will have to go back to the 'by_author' method and add an else block
# that returns all

# app\models\post.rb
class Post < ActiveRecord
	def self.by_author(author)
		if author.present?
			where(author: author)
		else
			return all
		end
	end

	def self.recent
		where('published_on > ?', 2.days.ago)
	end
end

# 'all' in rails4 is a chainable relation
# now when we call Post.by_author.recent if author is nil it will still return all recent posts by_author
#--------------------------------

# SCOPE VERSION

# scope version doesnt require as much code and does the same thing
# and we dont have to worry about returning a chainable relation (all for example)
# because scopes always return a chainable object

# app\models\post.rb
class Post < ActiveRecord
	scope :by_author, ->(author){ where(author: author) if author.present? }
	scope :recent, -> { where('published_on > ?', 2.days.ago) }
end
