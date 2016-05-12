# Serialization Code Should Not Be In Controller

class ItemsController < ApplicationController
  def index
    @items = Item.all

    respond_to do |format|
      format.html
      format.json {
        render json: @items,
          except: [:created_at, :updated_at],
          include: {comments: { only: :id }}
      }
    end
  end
end

# serialization logic should not be placed in the controller
# a better way to do this would be from your model
# by overriding the as_json method , you can also customize the JSON that is sent back
# However, placing serialization code in the model breaks the Single Responisibility Principle

class Item < ActiveRecord::Base
  has_many :comments

  def as_json(params={})
    super(except: [:create_at, :updated_at],
      include: { commetns: {only: :id }}
      )
  end
end

# now this ActiveRecord model is not only responsible for persisting to the database and a couple validations
# but its also responsible for formatting to custom JSON

# ------------------------------------------------

# this is where Active Model Serializers come in
# they help you decouple serialization code out of your model

# ActiveModelSerializers replace "hasd-driven development" with object-oriented development
  # 1. Decouples serialization code from the model
  # 2. Convention over configuration
  # 3. Access to url helper methods
  # 4. support for associations (built-in support for associations)

# heres how to use ActiveModelSerializers you add it to your Gemfile

# Gemfile
gem 'active_model_serializers', github: 'rails-api/active_model_serializers'
# we point to the github repo to use extra features that are not yet available at the current moment

# ALSO NEED TO REMOVE jbuilder from your Gemfile to avoid conflicts with active_model_serializers
# escpecially when running rails generators
gem 'jbuilder', '~> 1.2' # <------- REMOVE THIS

# next run
$ bundle install
# or just bundle

# the first thing you will notice is that your JSON responses will automatically have a root node
# JSON response:

# before active_model_serializers gem installation
[{"id":1},{"id":2},{"id":3}]

# after active_model_serializers gem installation
{"items":[{"id":1},{"id":2},{"id":3}]}

# the root node in this example is 'items'
# the root node is automatically added by the active_model_serializers gem
# the items root node makes this response comliant with the JSON API hypermedia type
# visit http://jsonapi.org for more information on JSON API hypermedia type

# back into the controller
# if you want to use the Rails built-in serialization, theres nothing that you have to do
# app\controllers\items_controller.rb
class ItemsController < ApplicationController
  def index
    @items = Item.all

    respond_to do |format|
      format.html
      format.json { render json: @items} # <---- same old render call
    end
  end
end

# you can use the respond_to block with the JSON format like in the example above
# or
# you can use 'respond_with' like in the example below
class ItemsController < ApplicationController
  respond_to :json, :html

  def index
    @items = Item.all
    respond_with @items
  end
end

# --------------------------------------------------------------
# Creating a Serializer

# Rails has a generator available to create new serializers
$ rails generate serializer Item
# this cmd would generate a serializers directory, and an item_serializer.rb file

# app\serializers\item_serializer.rb
class ItemSerializer < ActiveModel::Serializer
  attributes :id
end

# next inside your items controller you can still use the same render call
# app\controllers\items_controller.rb
render json: @items
# this render call would still send the JSON back to the client with the root node added by default
{"items":[{"id":1},{"id":2},{"id":3}]}
# by convention ActiveModelSerializers will look for a serializer named after the class thats passed as an argument

# ------------------------------------------------------------------
# Using a Custom Serializer
# You many want to skip the convention and provide your own custom serializer

# app\controllers\items_controller.rb
render json: @items, serializer: SomeOtherSerializer # <--- passing a different serializer to override the convention
# this is an option to render which overrides the serializer
# or
# you can specify your serializer class in your ActiveRecord Model
# app\models\item.rb
class Item < ActiveRecord::Base
  def active_model_serializer
    SomeOtherSerializer
  end
end

# both of these ways will override your ActiveModel Serializer method
# below is the example of the custom serializer that is being used by our item model
# app\serializers\some_other_serializer.rb
class SomeOtherSerializer < ActiveModel::Serializer
  attributes :id, :description
end
# notice that its using both ID and description as attributes, and not just the default, ID
# -------------------------------------------------------------------
# here is how to remove the root node
# sometimes you need to remove the root node because other clients might depend on the response type

# first, you can pass root: false to the render call
render json: @items, root: false # <--- this will remove the root node
# this will reformat the json response as such:
[{"id":1},{"id":2},{"id":3},]

# or
# you can pass in a custom serializer
# in the example below we are calling and ItemsCollectionSerializer
render json: @items, serializer: ItemsCollectionSerializer
# notice how the base class is ActiveModel::ArraySerializer
# ActiveModel::ArraySerializer is the base class for collections
# app\serializers\custom_collection_serializer.rb
class ItemsCollectionSerializer < ActiveModel::ArraySerializer
  self.root = false
end
# inside of the custom serializer we set root to false
# this in affect removes the root node
# so this
{"items":[{"id":1},{"id":2},{"id":3}]}
# becomes this
[{"id":1},{"id":2},{"id":3},]

# ----------------------------------------------------------------------
# heres how to add custom properties to your serializers

# app\serializers\item_serializer.rb
class ItemSerializer < ActiveModel:: Serializer
  attributes :id, :name, :url

  def url
    item_url(object)
  end
end

# here we have out Item Serializer, that defines attributes
# ID, name, and URL
# URL, is not a property from the Item model, but rather a method that being defined now inside the ItemSerializer
# inside this method we call item_url helper and pass in an object as an argument
# the object method gives us access to the object being serialized, in this case, its an item

# so the output of the serializer would be like this
{
  "items": [
    {
      "id":1,
      "name": "Avatar",
      "url": "http://localhost/items/1"
    },
    {
      "id":2,
      "name": "The Hobbit",
      "url": "http://localhost/items/2"
    },
  ]
}
# an array of items, an ID, the name, and the URL
