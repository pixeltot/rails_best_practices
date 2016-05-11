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
    post.respond_to?(method_name, include_private) || super
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

# Using Decorators For View Output

# app\helpers\posts_helper.rb
module PostHelper
  def publication_date(date)
    post.created_at.strftime '%Y-%m-%d'
  end
end

# app\views\posts\show.html.erb
# <span><%= publication_date @post %> </span>

# here we have our PostsHelper module, with the publication date helper method
# this method takes a post and formats the created update

# a couple of issues with view helpers:
  # 1. pollute the global namespace with methods specific to a model
  # 2. forces a functional approach within an object oriented domain model

# for example, nothing stops us here from passing a user object to the publication_date method
# since the user object might also have a create_at view
# so... it is still allowed to be used with other objects, but that would be wrong!

# a better place for our publication_date method is inside our post_decorator.rb class
# this way we can call publication_date as an instance method on our post decorator object, which gives
# us a more consistent object-oriented approach throughout the view

# app\decorators\post_decorator.rb
class PostDecorator
  def publication_date
    post.create_at.strftime '%Y-%m-%d'
  end

  def method_missing(method_name, *args, &block)
    '...'
  end

  def respond_to_missing?(method_name, include_private = false)
    '...'
  end
end

# app\views\posts\show.html.erb
# <span> <%= @post_decorator. publication_date %></span>

# -------------------------------------------------------

# another way we can use decorators is to output HTML
# in this exaxmple we have a PostHelper with a post_classes method

# app\helpers\post_helper.rb
module PostHelper
  def post_classes(post)
    classes = ['page']
    classes << 'front-page' if post.is_front_page?
    classes
  end
end

# this method takes a post and constructs a collection of CSS classes based on the post's attributes
# then in the view, we use the output from the post_classes method to determine the classes

# app\views\posts\show.html.erb
# <article class="<%= post_classes(@post) %>">
#   <%= @post.content %>
# </article>

# this is a great starting point but it doesnt scale well as your view specific logic grows
# view specific logic that outputs HTML classes

# ---------------------------------------------------------------

# so lets move our post_classes method into our PostDecorator, and call it 'classes'
# we dont have to pass any argument to this method
# because we have access to the post via our attr_reader

# app\decorator\post_decorator.rb
class PostDecorator
  attr_reader :post

  def classes
    classes = ['page', 'btn']
    classes << 'cover' if post.is_front_page?
    classes
  end
end

# and in the show template, we can go back to using a more object-oriented approach
# by calling the classes method on the post_decorator

# app\view\posts\show.html.erb
# <article class="<%= @post_decorator.classes %>">
#   <%= @post_decorator.content %>
# </article>
