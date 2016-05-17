# Faster Queries

@items = Item.where('due_at' < ?, 2.days.from_now)
# heres what this will output
# SELECT "items".* FROM "items" WHERE (due_at < '2013-06-14" 17:10:48:902238')

# => #<ActiveRecord::Relation [#<Item id:31, name: "Chair", due_at: "2013-06-19">,
#<Item id: 32, name: "Table", due_at: "2013-06-19">,
#<Item id:33, name: "Chouch", due_at: "2013-06-19">, ...]>

# this query returns an Active Relation, which is a collection of ActiveRecord objects
# when we call items.class, we can see that its an Active Relation item,
# and the first item in the collection is an ActiveRecord object
# each element in the collection is an ActiveRecord object

items.class # => ActiveRecord::Relation::ActiveRecord_Relation_Item
items.first.class # => Item(id: integer, name: string, due_at: datetime)

# however, your web page might not need to display all of the columns in the database
# you might only need the id
# if this is the case you can use the 'select' method

@items = Item.select(:id).where('due_at < ?', 2.days.from_now )
# the 'select' method will reduce the number of columns loaded from the database
# heres the output

# SELECT id FROM "items" WHERE (due_at < '2013-06-14 17:20:39:237551')
# => #<ActiveRecord::Relation [#<Item id: 31>, #<Item id:32>, #<Item id: 33>,
#Item id:34>, ...]>

# this is the SQL it generates, and it only selects the id
# only the id property is set on item objects

items.class # => ActiveRecord::Relation::ActiveRecord_Relation_Item
items.class.first # => Item(id: integer, name: string, due_at: datetime)
# this is more effecient on the databse side, but when you call items.class it still returns an ActiveRecord Relation
# and each element of the collection is still an ActiveRecord object
# so you are still creating different Item objects for each row returned from the database
# this is wasteful when all you are trying to get are the ids

# this is where the 'pluck' method comes in
# the 'pluck' method returns an array of values instead of the ActiveRecord object
# for example:
ids = Item.where('due_at < ?', 2.days.from_now ).pluck(:id)
# here is the SQL this outputs

# SELECT "items". "id" FROM "items" WHERE (due_at < '2013-06-14 17:25:53.592523')
# => [31, 32, 33]

# by looking at the SQL that is generated it shows that it reduces the number of columns loaded from the database
# also notice the array of values returned, and each element of the array, is just a number, instead of an ActiveRecord object
# by avoiding the creation of ActiveRecord objects, you can really speed things up

ids.class # => Array
ids.first.class # => Fixnum

# 'pluck' avoids creating ActiveRecord objects
# the 'pluck' method has been around since Rails 3, but in Rails 4 pluck is now able to take multiple arguments
# for example:
@items = Item.where('due_at < ?', 2.days_from_now).pluck(:id, :name)
# as you can see, we are now plucking for id and name
# here is the SQL generated

# SELECT "items"."id", "items"."name" FROM "items" WHERE (due_at < '2013-06-14 17:29:48.734794')
# => [[31, "Chair"], [32, "table"], [33, "Couch"]]

# notice its only fetching for the id and name columns from the database
# and it now returns an array of arrays '[[],[],[]]' <--- a threesome!

items.class # = Array
items.first.class # => Array

# this still avoids the creation of ActiveRecord objects
# pluck is a great way to reduce your application's memory footprint!
# this makes your application faster
