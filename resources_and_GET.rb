# REST is all about the resources
# anything that can be given a name can be a resources
# nouns, in others words, people, places, or things
# for example:
  # 1. a music playlist
  # 2. hipsters
  # 3. survivors
  # 4. remaining medical kits
# all the above can be a resource

"A resource is a conceptual mapping to a set of entities,
not the entity that corresponds to the mapping at any particular point in time"
- Steve Klabnik

# we use the GET method to retrieve imformation from a given URI
# for example to read a specific playlist , a client issues a GET request
# to /playlist/13, which is the URI
# the server might respond with OK, an return the playlist 13
# the GET method is SAFE - it should NOT take any action other than retrieval
# it will not create or update any resources on the server
# its Idempotent - sequential GET requests to the same URI should not generate side-effects
# -------------------------------------------------------------------------
# integration tests simulate clients interactin with the API
# for example:

# config\routes.rb
namespace :api, path: '/', constraints: {subdomain: 'api'} do
  resources :zombies
end

# here is an integration test for listing the zombies

# test\integration\listing_zombies_test.rb
require 'test-helper'

class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'} # <--- required for testing with subdomain constraint

  test 'returns list of all zombies'
    ...
  end
end

# first thing that this does is call the host bang method like this:
host!
# this is required for testing with subdomains
# Rails uses the example.com domain whenever Rails runs your application and test
# so...you need to override that wiith our specific sub-domain
# in this case its:
api.example.com
# once this is done, you can start writing tests
# --------------------------------------------------

# here is a test example:
# test\integration\listing_zombies.rb
require 'test_helper'
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns list of all zombies' do
    get '/zombies'
    assert_equal 200, response.status
    refute_empty response.body
  end
end

# use a GET method, which issues a GET request to the given URI, /zombies
# first thing to do is create an assertion for the status code, which needs to be 200
# the 200 status code means the request has succeeded
# the 200 status code also means the response should include the resource in the response body

# another way to write the same thing is to use a helper method from Rack Utils
# for example:
require 'test helper'
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns list of all zombies' do
    get '/zombies'
    assert response.success?
end

# ---------------------------------------------------------

# Listing Resources

# app\controllers\api\zombies_controller.rb
module API
  class ZombiesController < ApplicationController
    def index
      zombies = Zombie.all
      render json: zombies
    end
  end
end

# inside the ZombiesController , which is part of the API module
# we created the index action
# inside of that, we start by fetching all the zombies and returning them as JSON
# behind the scenes, Rails is calling the to_json method, which serializes all properties to JSON

zombies.to_json # <--- like this
# if you call to_json on a single zombie object it would serialize just that one object, and return only one zombie
zombie.to_json # <--- like this

# by default, Rails returns a 200 response for calls to render
# but you can pass the status code as the second option to render
# like this:
module API
  class ZombiesController < ApplicationController
    def index
      zombies = Zombie.all
      render json: zombies, status: 200 # <--- notice the status code we added
    end
  end
end

# the to_json is built into Rails, but doesnt scale well when your logic for serializing object gets too complex
# for a more advanced solution to serializing objects to JSON check out ActiveModel Serializers

# -----------------------------------------------------------------------------
# Path Segmented Expansion
# for respresenting resources on the URL Rails uses whats called Path Segmented Expansion
# this means arguments in the URI are seperated using a slash... '/' <--- like this

# for example:
# lets fetch a specific zombie, you add slash :id to the URI
# /zombies/:id
# /zombies/:id/victims
# /zombies/:id/victims/:id
# its the same for additional arguments

# this means that if you access:
# /zombies?id=1
# it will NOT be routed to
  Zombies#show
# but to
  Zombies#index

# Most URI will not depend on query string parameters, but its ok to use them sometimes
# for example: filters
# in this case you can list all the zombies, filtering for only those whose weapon is an axe
# /zombies?weapon=axe # <--- filters for weapon axe

# for searches if you want to search for all the zombies with the keyword john
# /zombies?keyword=john # <--- searches for john

# and also for pagination, if you want to list all the zombies in page 2, with 25 zombies per page
# /zombies?page=2&per_page=25 # <--- pagination
# -----------------------------------------------------------------------------

# Test Listing Resources With Query Strings
# lets implement this filter, and start by writing a test
# /zombies?id=1

# first in the setup you need to tell the host is going to be using the API sub-domain
# for example:
# test\integration\listing_zombies_test.rb
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns zombies filtered by weapon' do
    john = Zombie.create!(name: 'John', weapon: 'axe')
    joanna = Zombie.create!(name: 'Joanna', weapon: 'shotgun')

    get '/zombies?weapon=axe'
    assert_equal 200, response.status
  end
end

# in the test block you want to return zombies filtered by weapon
# first is John, whose weapon is an axe
# second is Joanna, whose weapon is a shotgun
# right now the object creation logic is simple,
# but if it gets too verbose/complex, its better to use fixtures, or FactoryGirl

# next, check for the status code, and parse out the response body that was returned
# we use JSON.parse for that, passing a symbolize_names option
# for example:
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns zombies filtered by weapon' do
    john = Zombie.create!(name: 'John', weapon: 'axe')
    joanna = Zombie.create!(name: 'Joanna', weapon: 'shotgun')

    get '/zombies?weapon=axe'
    assert_equal 200, response.status

    zombies = JSON.parse(response.body, symbolize_names: true) # <---check it out
  end
end

# symbolize_names will convert the keys of the hash from strings to symbols
# which is typically how we work with hashes in Ruby
# here is what that looks like:
# from this
{ 'id' => 51, 'name' => "John" } # <--- notice these keys were originally strings
# to this
{ :id => 51, :name => "John" } # <--- notice these keys are now changed to symbols

# next we loop over the zombie names that are returned
# and we make sure that John, which is the zombie with the weapon, is included
# and joanna, which is a zombie with a shotgun, is NOT included
# for example:
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup { host! 'api.example.com' }

  test 'returns zombies filtered by weapon' do
    john = Zombie.create!(name: 'John', weapon: 'axe')
    joanna = Zombie.create!(name: 'Joanna', weapon: 'shotgun')

    get 'zombies?weapon=axe'
    assert_equal 200, response.status

    zombies = JSON.parse(response.body, symbolize_names: true)
    names = zombies.collect { |z| z[:name] }
    assert_includes names, 'John'     # <--- included
    refute_includes names, 'Joanna'   # <--- NOT included
  end
end
# we havent implemented this feature yet, so our test are currently failing
# -----------------------------------------------------------------------------
# Listing Resources With Filter
# inside of the API ZombiesController, start by fetching all of the zombies
# for example:
# app\controllers\api\zombies_controller.rb
module API
  class ZombiesController < ApplicationController
    def index
      zombies = Zombie.all # <--- 'all' returns a 'chainable scope' since Rails 4
      if weapon = params[:weapon]
        zombies = zombies.where(weapon: weapon) # <--- added a dynamic filter to the 'all' method
      end
      render json: zombies, status: 200
    end
  end
end
# then, we check for a weapons parameter
# if its present, we're going to filter our query only to the zombies with that specific weapon
# if you're wondering about Zombie.all issuing a query to the database
# remember that in Rails 4 the 'all' method returns a chainable scope
# which allows you to add filters dynamically
# next we'll return our zombies as JSON with the status 200
# now your test will pass
# -----------------------------------------------------------------------------

# Test Retrieving One Zombie
# start by writing a test

# test\integration\listing_zombies_test.rb
class ListingZombiesTest < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns zombie by id' do
    zombie = Zombie.create!(name: 'Joanna', weapon: 'axe')
    get "/zombies/#{zombie.id}"
    assert_equal 200, response.status

    zombie_response = JSON.parse(response.body, symbolize_names: true)
    assert_equal zombie.name, zombie_response[:name]
  end
end

# here we create a zombie record named joanna
# next we issue a get request to that zombie id
# which gets routed to Zombies#show action in the controller
# next, check for a 200 status code
# and parse the response body back
# last, check the name that you got back in the response
# see if it matches the name of the object you just created
# joanna

# with the test failing, move on to the implementation
# -----------------------------------------------------------------------------

# Returning One Zombie
# on the API ZombiesController, create the show action

# app\controllers\api\zombies_controller.rb
module API
  class ZombiesController < ApplicationController
    def show
      zombie = Zombie.find(params[:id])
      render json: zombie, status: 200
    end
  end
end
# next, fetch the zombie by its id, and return its JSON representation with the status 200
# now the test will pass

# another way that you can define this status
# instead of using the number 200, you can use the ':ok' symbol
# which is the same thing

# for example:
module API
  class ZombiesController < ApplicationController
    def show
      zombie = Zombie.find(params[:id])
      render json: zombie, status: :ok # <--- notice the :ok symbol is being used instead of 200
    end
  end
end

# visit this URL for all numerical status codes and symbols supported by Rails
http://guides.rubyonrails.org/layouts_and_rendering.html

# -----------------------------------------------------------------------------

# Looks like we can refactor our test file and clean up duplication

# test\integration\listing_zombies_test.rb
class ListingZombies < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns zombie by id' do
    zombie = Zombie.create!(name: 'Joanna', weapon: 'axe')
    get "/zombies/#{zombie.id}"
    assert_response = JSON.parse(response.body, symbolize_names: true)
    assert_equal zombie.name, zombie_response[:name]
  end
end

# this method
JSON.parse(response.body, symbolize_names: true)
# is used over and over again, across all the different integration tests
# so you can extract that into a helper method
# which will look like this
json(response.body)
# which is simply json that takes the response.body as an argument
# to implement this method, go back into the test helper file
# place it inside the ActiveSupport test case class

# test\test_helper.rb
ENV["RAILS_ENV"] ||="test"
require File.expand_path('../../config/evironment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
  fixtures :all

  def json(body)
    JSON.parse(body, symbolize_names: true)
  end
end

# you can now use this method across all your different tests
# like this:
class ListingZombies < ActionDispatch::IntegrationTest
  setup {host! 'api.example.com'}

  test 'returns zombie by id' do
    zombie = Zombie.create!(name: 'Joanna', weapon: 'axe')
    get "/zombies/#{zombie.id}"
    assert_response = json(response.body) # <--- check out the test helper method
    assert_equal zombie.name, zombie_response[:name]
  end
end

# -----------------------------------------------------------------------------

# Using Curl To Test Our API with Real Network Requests

# another helpful way to test the API as you develop it
# is using the Curl cmd
# curl is a cmd line tool that issues real HTTP requests over the network

# for example:
$ curl http://api.example.com:3000/zombies
# pass the URL to the cmd curl as an argument
# this defaults to a GET request to that URL
# this will desplay the response body in the terminal

# curl also works fine with query strings
# for example:
$ curl http://api.example.com:3000/zombies?weapon=axe
# this will return only the zombies with the axe weapon

# if you want to display the response headers use the '-I' option
# for example:
$ curl -I http://api.example.com:3000/zombies/7
