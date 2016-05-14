# Associations
# you can use associations from within your serializers

# app\serializers\item_serializer.rb
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :url

  has_many :comments

  def url
    item_url(object)
  end
end

# in the example above we've defined id, name, and URL
# then in our URL methoed we are calling a route helper and passing in object as an argument
# object represents the object being serialized, in this case item
# for each item, we also want to serialize its comments, we do that by adding the relationship method has_many :comments
# now each element of the association is serialized
# when a custom serializer isnt fond, the default Rails serialization is used

# here is what the output looks like:
{
  "items":[
    {
      "id": 1,
      "name":"Avatar",
      "url": "http://...",
      "comments": [
        {
          "id": 1,"item_id": 1,
          "description":"This movie ...",
          "rating": "bad",
          "created_at": "2013-06-03 ...",
          "updated_at": "2013-06-03 ...",
          "approved": false
        }
      ]
    }
  ]
}

# child objects are embedded inside of their parents.
# in this case, comment objects are serialized inside of each item
# instead of serializing the whole comment object, we might want to just fetch their ids, which will give use a huge performance boost
# anytime less data is transferring down to the client the faster it will be

# to do this we have to embed: :ids as an option to has_many,
# which will return the IDs for the associations, instead of the entire object
# for example:
# app\serializers\item_serializer.rb
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :url

  has_many :comments, embed: :ids # <-- checkout the embed option of the has_many relationship

  def url
    item_url(object)
  end
end

# embed: :ids will return ids for the associations instead of the entire object

# here is what the output looks like:
{"items":[{"id":4,"name":"Avatar","url":"http://localhost:3000/items/4",
"comment_ids":[14,15,16,17]},{"id":5,"name":"The Hobbit",
"url":"http://localhost:3000/items/5", "comment_ids":[18,19,20,21]}...]}

# this offers a performance improvement and helps avoid data duplication
# notice that we have comment_ids property with an array of ids

# another way we can specify that we want all association ids is by using the embed class method instead.
# for example
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :url

  has_many :comments
  has_many :pictures

  embed :ids # <--- embed class method

  def url
    item_url(object)
  end
end
# this will apply to all the associations of the serializer
# be using the embed class method, all existing associations will embed ids instead of objects
# so in this case :comments, :pictures
# the output will look like this:
{"items":[{"id":4 "name":"Avatar","url":"http://localhost:3000/items/4",
"comment_ids":[14,15,16,17], "picture_ids":[3,4,5,6]},
{"id":5,"name":"The Hobbit", "url":"http://localhost:3000/items/5",
"comment_ids":[18,19,20,21], "picture_ids":[7,8,9,10]}...]}
# if you notice in the output we have both commet ids, and picture ids

# ------------------------------------------------------------------

# Side-Loading Associations
# in addition to embedding ids for associations, you might want also want to side load the objects themselves.
# by side-loading association objects, you can reduce the number of http requests
# all you have to do is pass the include: true option to your embed method like this:
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :url

  has_many :comments
  embed :id, include: true # <--- associations will be included at the root level

  def url
    item_url(object)
  end
end
# up to this point, comments has been using Rails default serialization
# but once we include side-loading, then we'll need to create its own custom serializer
# in this case comment serializer under the app\serializers\comment_serializer.rb directory
class CommentSerializer < ActiveModel::Serializer
  attributes :id, :description
end
# side-loading associations need a corresponding serializer

# in the controller nothing has changed, we can still use render or respond_with method
# app\controllers\items_controller.rb
render json: @items
# or you can use the respond_with
respond_with @items
# here is what the output will look like
{
  "comments": [  # <---comments are included at the top level
    { "id": 1106, "description": "..." },
    { "id": 1107, "description": "..." }
  ],
  "items": [ # <--- side-loading requires presence of a root element
    {
      "id": 133,
      "name": "Avatar",
      "url": "http://...",
      "comment_ids": [1106, 1107] # <-- # ids can be used by client-side Javascript libraries to fetch side-loaded comments

    }
  ]
}
# notice how wer're embedding our ids for comment_ids, and the comment objects are also included at the top level
# in this case, because we're side loading associations, it requires the presence of a root element
# side-loading requires the presence od a root element, otherwise it raises an error
# ActiveModel::Serializer::IncludeError:Cannot serialize comments when ItemSerializer does not have a root!

# -------------------------------------------------------------

# More Custom Methods
# heres how to customize the records returned by our associations

# notice that inside of our comment class we have an approved scope that returns all of the approved comments
# app\models\comment.rb
class Comment < ActiveRecord::Base
  belongs_to :item
  scope :approved, -> { where(approved: true) }
end

# we want our serializer to only include approved comments
# to do that, we override our comments method
# now using the object method, which again refers to the item being serialized
# 'object' means 'item' that is being serailized
# we can then call comments, and then the approved scope
# this way we can override the association methods to only return the records that we want


# app\serilizer\item_serializer.rb
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name

  has_many :comments

  def comments # <--- this will override association methods to filter records
    object.comments.approved
  end
end

# --------------------------------------------------------
# Take Control Over Attributes
# lets say you wanted to add a specific property based on whether the current user had a premium account or not?
# first, we override the attributes method, which gives us total control over the data that's serialized

# app\serializers\item\item_serializer.rb
class ItemSerializer < AxctiveModel::Serializer
  attributes :id, :name, :price

  def attributes
    data = super # <--- super will look for the attributes defined at the top level
    if current_user.premium_account? # <--- current_user helper method
      data[:discounted_price] = object.discounted_price
    end
  end
end

# we start off by calling super, super looks for the attributes defined at the top level
# so in this case id, name, and price
# then we need to check if the current user has a premium account
# by default Rails gives you access to the current_user helper method from controller
# if the user has a premium account, we want to set the discounted_price property and return the data

# here is what the output looks like with a user that has a premium account (notice the discounted_price that its showing)
{
  "items": [{
    "id": 133,"name": "Avatar",
    "price": "10.5", "discounted_price": "8.5",
  }]
}

# ---------------------------------------------------------------
# Custom Scope
# for some reason, your application might use a different scope than current_user
# for example, it could use logged_user

# if this is the case, then you can tell active model serializers to look for a different scope either by...
  # 1. calling the serialization scope method in the name of the scope,
  # 2. or by passing scope and scope_name as options to the render method

# app\serializers\item_serializer.rb
class ItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :price

  def attributes
    ...
    logged_user.premium_account?
  end
end

# 1. calling the serialization scope method in the name of the scope,
# app\controllers\application_controller.rb
class ApplicationController < ActionController::Base
  serialization_scope :logged_user
end

# or

# 2. or by passing scope and scope_name as options to the render method
render json: @items, scope: logged_user, scope_name: :logged_user
# ---------------------------------------------------------------------
