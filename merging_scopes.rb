# Merging Scopes
# --------------
# relational example of merging scopes
# the problem here is that we have the same query logic duplicated in defferent places
# in the Comment class and in the Post class

class Comment < ActiveRecord
  belongs_to :post
  scope :approved, ->{ where(approved: true) } # <------ same as post query
end

class Post < ActiveRecord
  has_many :comments
  scope :with_approved_comments,
    ->{ joins(:comments).where('commments.approved = ?', true) } # <------- same as comments query
end

Post.with_approved_comments # here is where we call the approved comments which comes from Post class

# here is what this will generate:
# "SELECT "posts".* FROM "posts" INNNER JOIN "comments" ON "comments"."post_id" =
# "posts". "id" WHERE ("comments". "approved" = 't')

#------------------------------------------------------------------------------------

# we can fix this duplication by using the .merge method for example:

class Comment < ActiveRecord
  belongs_to :post
  scope :approved, ->{ where(approved: true) }
end

class Post < ActiveRecord
  has_many :comments
  scope :with_approved_comments,
  ->{ joins(:comments).merge(Comment.approved) } # checkout the .merge method working
end

Post.with_approved_comments

# here is what this will generate, notice the same SQL, fuck yea!:
# "SELECT "posts".* FROM "posts" INNNER JOIN "comments" ON "comments"."post_id" =
# "posts". "id" WHERE ("comments". "approved" = 't')

#--------------------------------------------------------

# Rails 3
User.active.inactive
# query in the last scope overrides the first one
# SELECT * FROM users WHERE state = 'inactive'

# Rails 4
User.active.inactive
# will append conditions
# Select * FROM posts WHERE state = 'active' AND state = 'inactive'

# Notice how big of a difference the SQL statements are from Rails3 to Rails4
# if you want Rails4 to act like Rails3 and have the last scope overide the first one
# then you have to use the merge for the last 'where' wins logic

# Rails 4
User.active.merge(User.inactive)
# SELECT * FROM users WHERE state = 'inactive'

# Notice now that this SQL statement is the same as it is in Rails 3


