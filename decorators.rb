# Decorators are used for view logic that does not belong in the model

# in this example the model is polluted with view-related business logic
# it would be better if that was not in the model but in a decorator

# app\models\post.rb
class Post < ActiveRecord::Base
  def is_front_page?
    published_at > 2 .days.ago
  end
end

# app\controllers\posts_controller.rb
class PostsController < ApplicationController
  def show
    @post = Post.find(params[:id])
  end
end

# app\views\posts\show.html.erb

# <% if @post.is_front_page? %>
#   <%= image_tag(@post.image) %>
# <% end %>

# -------------------------------------------------------------------
# decorators help view specific logic in our models into decorator classes
# in this example we move is_front_page? method out of our Post model into the Post decorator class

# app\models\post.rb
class Post < ActiveRecord::Base

end

# app\controllers\posts_controller.rb
class PostsController < ApplicationController
  def show
    post = Post.find(params[:id])
    @post_decorator = PostDecorator.new(post)
  end
end

# app\views\posts\show.html.erb
# <% if @post_decorator.is_front_page? %>
#   <%= image_tag(@post_decorator.image) %>
# <% end %>

# app\decorators\post_decorator.rb
class PostDecorator
  attr_reader :post

  def initialize(post)
    @post = post
  end

  def is_front_page?
    post.published_at > 2.days.ago
  end
end

# extract presentation logic out to decorators

# we call @post_decorator.image in the view, but because we dont have that method yet it will cause this error
# undefined method 'image' for #<PostDecorator:0x007fc8ce4ace98>
# to fix this we are going to have to implement method missing
# delegating methods to the underlying object
# this will forward any  undefined method to the wrapped object
# in this case... 'post'
# we do that by calling post.send and passing all the arguments from method_missing

# app\decorators\post_decorator.rb
class PostDecorator
  ...

  def method_missing(method_name, *args, &block)
    post.send(method_name, *args, &block)
  end
end

# so now you call @post_decorator.image
# it will forward the method using method_missing, and we'll get the post image back

@post_decorator = PostDecorator.new(post)
@post_decorator.image # => '...'
@post_decorator.respond_to?(:image) # => false

# however if we ask this object if it will respond to image, it will return false
# this is because it will not search the objects ancestors chain, and can cause unexpected behavior
# to fix this we have to implement respond_to_missing
# and ask post if it responds to the given method, otherwise, call super, which will invoke the respond_to_missing from its parent object

def respond_to_missing(method_name, include_private = false)
    post.respond_to?(method_name, include_private || super)
end

# now, if we ask a PostDecorator if it responds to image , it'll return true
# because now it will properly search through the objects acenstors chain
# ALWAYS DEFINE RESPOND_TO_MISSING? WHEN OVERRIDING METHOD_MISSING

# WE WANT TO USE DECORATORS TO ATTACH PRESENTATION LOGIC TO AN OBJECT DYNAMICALLY

# 1. Transparent to clients
# 2. "Wrap" another object
# 3. Delegate most methods to the wrapped object.
# 4. Provide one or two methods of their own.
# ---------------------------------------------------------
