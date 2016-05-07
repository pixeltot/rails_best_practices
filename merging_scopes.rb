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
