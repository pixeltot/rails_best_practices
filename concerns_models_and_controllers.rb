#

# this is a Post class which has_many comments, a polymorphic association
# represented by the Comments class

# app\models\posts.rb
class Post < ActiveRecord::Base
  has_many :comments, as: :commentable

  def comments_by_user(id)
    commnets.where(user_id: id)
  end
end

# here we have an Image class which also has_many comments, which is also a polymorphic association
# and is also represented by the comments association

# app\models\image.rb
class Image < ActiveRecord::Base
  has_many :comments, as: :commmentable

  def comments_by_user(id)
    comments.where(user_id: id)
  end
end

# both the Post and Image class share the comments_by_user method
# the comments)by_user method queries for comments by a specific user



