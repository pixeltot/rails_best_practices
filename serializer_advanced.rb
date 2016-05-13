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





