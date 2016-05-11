# concerns help extract duplicate code in modules that can be reused in multiple controllers or models
# below are some examples on how to do just that

# this is a Post class which has_many comments, a polymorphic association
# represented by the Comments class

# app\models\posts.rb
class Post < ActiveRecord::Base
  has_many :comments, as: :commentable

  def comments_by_user(id)
    comments.where(user_id: id)
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
# the comments_by_user method queries for comments by a specific user

# here we have the Comment class that shows the polymorphic association
# app\models\comment.rb
class Comment < ActiveRecord::Base
  belongs_to :commentable, polymorphic: true
end

#---------------------------------------------

# here is a better way to do this without having to duplicate in the Post and Image class
# we can remove this duplication from the Image and Post class by extracting the code into a module
# extract the duplicate code into a model concen
# the concerns directory is a place to put concern modules that will be mixed into your models
# using the included hook method which is automatically called by ruby,
# when we mix this module into a model will dynamically add the comments association to
# whatever model includes the Commentable module
# module methods become instance methods on the target calss

# module Commentable
module Commentable
  def self.included(base)
    has_many :comments, as: :commentable
  end

  def comments_by_user(id)
    comments.where(user_ud: id)
  end
end

# Post class
# app\models\post.rb
class Post < ActiveRecord::Base
  include Commentable
end

# Image class
# app\models\image.rb
class Image < ActiveRecord::Base
  include Commentable
end

# now we can still call comments_by_user on the @post and @image objects
@post.comments_by_user(id)
@image.comments_by_user(id)

# -------------------------------------------

# we can simplify our Commentable module by extending from ActiveSupport::Concern
# ActiveSupport::Concern adds the included method
# this allows you to use the included block like in the examnple below to add the associations
# code inside the included block runs in context of the target class

# app\models\concerns\commentable.rb
module Commentable
  extend ActiveSupport::Concern

  inluded do
    has_many :comments, as: :commentable
  end

  def comments_by_user(id)
    comments.where(user_id: id)
  end
end

# --------------------------------------------------

# ActiveSupport::Concern automatically includes methods from the ClassMethods module as class methods on the target class
# for example

# app\models\concerns\commentable.rb
module Commentable
  extend ActiveSupport::Concern

  module ClassMethods   # <======== ClassMethods module nested inside a concerns module
    def upvote(comment)
      ...
    end
  end
end

# methods declared inside of the inner module become class methods on target class
Post.upvote(@comment)
# or
Image.upvote(@comment)

#-----------------------------------------------------

# concerns are not just for model
# they can be used in controllers too, inside the app\conrollers\concerns directory
# for example

# app\controllers\images_controller
class ImagesController < ApplicationController
  def show
    @image = Image.find(params[:id])
    file_name = File.basename(@image.path)
    @thumbnail = "/thumbs/#{file_name}"
  end
end

# app\controllers\videos_controller.rb
class VideosController < ApplicationController
  def show
    @video = Video.find(params[:id])
    file_name = File.basename(@video.path)
    @thumbnail = "/thumbs/#{file_name}"
  end
end

# both the Videos and Images controllers are duplicating file_name and @thumbnail instance variable
# File.basename(passing in the argument) to interplolate a string inside the thumbnail instance variable
# here is how we can fix this duplication and encapsulate the duplication
# the controllers directory has a concerns directory
# which is where you will place the Previewable module to contain the duplicate code
# so... for both models and controllers we can extract duplicate code and put them into modules
# which rails 4 calls concerns

# app\controllers\concerns\previewable.rb
module Previewable
  def thumbnail(attachment)
    file_name = File.basename(attachment.path)
    "/thumbs/#{file_name}"
  end
end

# now...to call our thumbnail method from our controllers just inlude the Previewable module
# simply mix in the new module in the controller using include

# app\controllers\images_controller.rb
class ImageController < ApplicationController
  include Previewable
  def show
    @image = Image.find(params[:id])
    @thumbnail = thumbnail(@image)
  end
end

# app\controller\videos_controller.rb
class VideosController < ApplicationController
  include Previewable
  def show
    @video = Video.find(params[:id])
    @thumbnail = thumbnail(@video)

  end
end

# ActiveSupport::Concern was added in Rails 3
# utility methods for module mixins
