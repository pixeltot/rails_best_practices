# Routes, REST, Constraints, Namespaces
# Routes are a good starting point for implementing an API
# you can define your routes inside the routes\config.rb
# running the cmd $ rake routes will let you see the routes available
$ rake routes

# config\routes.rb
resources :posts

# rake routes
# resources :posts will give you these routes to work with:
   Prefix Verb   URI Pattern               Controller#Action
    posts GET    /posts(.:format)          posts#index
          POST   /posts(.:format)          posts#create
 new_post GET    /posts/new(.:format)      posts#new
edit_post GET    /posts/:id/edit(.:format) posts#edit
     post GET    /posts/:id(.:format)      posts#show
          PATCH  /posts/:id(.:format)      posts#update
          PUT    /posts/:id(.:format)      posts#update
          DELETE /posts/:id(.:format)      posts#destroy

# but you may not need all of these routes
# the resources method give you some options that you can use to restrict the routes you have
# which helps improve memory use and speeds up the routing process

# for example:
# config\routes.rb
resources :posts, except: :destroy
# using 'except:' here to restrict the destroy action, it will now be unreachable
# this is what you'll get , notice the destory action is no longer available
   Prefix Verb  URI Pattern               Controller#Action
    posts GET   /posts(.:format)          posts#index
          POST  /posts(.:format)          posts#create
 new_post GET   /posts/new(.:format)      posts#new
edit_post GET   /posts/:id/edit(.:format) posts#edit
     post GET   /posts/:id(.:format)      posts#show
          PATCH /posts/:id(.:format)      posts#update
          PUT   /posts/:id(.:format)      posts#update

# ---------------------------------------------------

# you can also use the 'only:' option in order to to restrict all routes except the route desired
# for example:
# config\routes.rb
resources :posts, only: :index
# this is what you'll get
Prefix Verb URI Pattern      Controller#Action
 posts GET  /posts(.:format) posts#index

# ----------------------------------------------------

# both 'only:' and 'except:' can also take an array of actions
# for example:
# config\routes.rb
resources :posts, only: [:index, :show]
# or
resources :books, except: [:destroy, :edit, :update]
# here is what the routes will look like:
  Prefix Verb URI Pattern          Controller#Action
   posts GET  /posts(.:format)     posts#index
    post GET  /posts/:id(.:format) posts#show
   books GET  /books(.:format)     books#index
         POST /books(.:format)     books#create
new_book GET  /books/new(.:format) books#new
    book GET  /books/:id(.:format) books#show
# -----------------------------------------------------

# using 'with_options' on routes
# with_options is a way to refactor duplication out of options passed to a series of method calls.
# for example, you could have:
# config\routes.rb
resources :posts, only: [:index, :new]
resources :books, only: [:index, :new]
recources :comments. only: [:index, :new]

# instead of duplicating only: :index on posts books and comments you can use the with_options like this:
with_options only: [:index, :new ] do |list_only|
  list_only.resources :posts
  list_only.resources :books
  list_only.resources :comments
end
# the options passed as arguments to the 'with_options' are automatically added to the resources in the block
# both examples will generate the same routes, but the 'with_options' way is more elegant
# the above example would generate these routes
    Prefix Verb URI Pattern             Controller#Action
post_index GET  /post(.:format)         post#index
      post GET  /post/:id(.:format)     post#show
     books GET  /books(.:format)        books#index
      book GET  /books/:id(.:format)    books#show
  comments GET  /comments(.:format)     comments#index
   comment GET  /comments/:id(.:format) comments#show
# -----------------------------------------------------------

# using constraints to enforce subdomains will load balance traffic at the DNS level
# which is way faster then doing it at the application level
# keeping your API under its own subdomain allows load balancing traffic at the DNS level

# config\routes
resources :episodes   # <--- this resources would create this route https://yoursite.com
resources :zombies, constraints: { subdomain: 'api' }
resources :humans, constraints: {subdomain: 'api' }

# the 'contsraints:' are used for creating sub-domains.
# in the example the sub-domain would be http://api.yoursite.come/zombies
# and the other sub-domain would be htto://api.yoursite.com/humans

# you can also write it this way, creating a constraints block
# both examples do the same thing

# config\routes.rb
resources :episodes

contraints subdomain: 'api' do
  resources :zombies
  resources :humans
end
# this is useful if you are using the same Rails cod base to serve both a website, and a web API

# using subdomains in development needs network configuration
# on Windows, look for
c:\Windows\system32\drivers\etc\hosts
# inside this file you have to map your local network interface which by default is 127.0.0.1
# that must be mapped to URLs that you would like to use in develpment

127.0.0.1 yoursite-dev.com
127.0.0.1 api.yoursite-dev.com
# the -dev is so you know that its in development mode and is optional

# the following URLs are now available on yout local machine
# keep in mind that the port number is still required, for example:
127.0.0.1 yoursite.com:3000
127.0.0.1 api.yoursite.com:3000


# THE ABOVE EXAMPLE DID NOT WORK FOR ME, SO I TRIED THIS
127.0.0.1 yoursite
127.0.0.1 api.yoursite

# this worked like a charm
# now when you run
$ rails s -b yoursite
# you can navigate to
yoursite:3000 # in your browser and your Rails app should be working
# ------------------------------------------------------------

# Keeping Web and API Controllers Organized

# its not uncommon to use the same Rails code base for both a web site and web API
# in this example all of the controllers are under the same namespace
# the same namespace means the same folder
# this can get confusing the more classes you create as your application grows

# for example:
# config\routes.rb
constraints subdomain: 'api' do
  resources :zombies # <--- serves a the web API
end

resources :pages # <--- serves a web site not the web API

# heres what your routes will look like, notice the folder :zombies and :pages are in,
# its the same namespace, they are both inside the controllers folder

     Prefix Verb   URI Pattern                 Controller#Action
    zombies GET    /zombies(.:format)          zombies#index {:subdomain=>"api"}
            POST   /zombies(.:format)          zombies#create {:subdomain=>"api"}
 new_zombie GET    /zombies/new(.:format)      zombies#new {:subdomain=>"api"}
edit_zombie GET    /zombies/:id/edit(.:format) zombies#edit {:subdomain=>"api"}
     zombie GET    /zombies/:id(.:format)      zombies#show {:subdomain=>"api"}
            PATCH  /zombies/:id(.:format)      zombies#update {:subdomain=>"api"}
            PUT    /zombies/:id(.:format)      zombies#update {:subdomain=>"api"}
            DELETE /zombies/:id(.:format)      zombies#destroy {:subdomain=>"api"}
      pages GET    /pages(.:format)            pages#index
            POST   /pages(.:format)            pages#create
   new_page GET    /pages/new(.:format)        pages#new
  edit_page GET    /pages/:id/edit(.:format)   pages#edit
       page GET    /pages/:id(.:format)        pages#show
            PATCH  /pages/:id(.:format)        pages#update
            PUT    /pages/:id(.:format)        pages#update
            DELETE /pages/:id(.:format)        pages#destroy

# a better solution would be to create a seperate namespace
# a seperate folder just for your API controllers
# most useful when web site and web API share the same code base

# for example:
# config\routes.rb
constraints subdomain: 'api' do
  namespace :api do
    resources :zombies
  end
end

resources :pages

# now your routes will look like this,
# notice that zombies routes are now in the api folder instead
# zombies resources are now part of the api namespace

         Prefix Verb   URI Pattern                     Controller#Action
    api_zombies GET    /api/zombies(.:format)          api/zombies#index {:subdomain=>"api"}
                POST   /api/zombies(.:format)          api/zombies#create {:subdomain=>"api"}
 new_api_zombie GET    /api/zombies/new(.:format)      api/zombies#new {:subdomain=>"api"}
edit_api_zombie GET    /api/zombies/:id/edit(.:format) api/zombies#edit {:subdomain=>"api"}
     api_zombie GET    /api/zombies/:id(.:format)      api/zombies#show {:subdomain=>"api"}
                PATCH  /api/zombies/:id(.:format)      api/zombies#update {:subdomain=>"api"}
                PUT    /api/zombies/:id(.:format)      api/zombies#update {:subdomain=>"api"}
                DELETE /api/zombies/:id(.:format)      api/zombies#destroy {:subdomain=>"api"}
          pages GET    /pages(.:format)                pages#index
                POST   /pages(.:format)                pages#create
       new_page GET    /pages/new(.:format)            pages#new
      edit_page GET    /pages/:id/edit(.:format)       pages#edit
           page GET    /pages/:id(.:format)            pages#show
                PATCH  /pages/:id(.:format)            pages#update
                PUT    /pages/:id(.:format)            pages#update
                DELETE /pages/:id(.:format)            pages#destroy

# heres what this means:
  # 1. it needs to go inside of the API module
  # 2. the module needs to be camelcase, API wouldnt work, needs to be Api
  # 3. it also needs to go inside of the api directory

  # for example:
  # app\controllers\api\zombies_controller.rb
  module Api
    class ZombiesController < ApplcationController
      ...
    end
  end

# notice that the :pages controller does not need to go inside of the api directory
# because its not part of the api
# it can still remain at the top level directory, or top level namespace

# for example:
# app\controllers\pages\pages_controller.rb
class PagesControllers < ApplicationController
  ...
end
# -------------------------------------------------------------------------

# if you wanted to use ALL CAPS for your API module, you can!
# however, you need to add an entry to the inflections file here:

# config\initializers\inflections.rb
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.acronym 'API'
end

# this will allow you to use ALL CAPS in your api module like this:
module API
  class ZombiesController < ApplicationController
    ...
  end
end
# --------------------------------------------------------------------------

# Removing duplication from the URL

# notice that the URL is duplicating the api
http://api.yourapp.com/api/zombies # <--- this is kind of ugly
# there is unnecessary duplication, repeating api in the sub-domain, and in the URI
# to fix this you can add a path: option to the namespace

# for example:
# config\routes.rb
constraints subdomain: 'api' do
  namespace :api, path: '/' do # <--- the path option is specifying route, just '/'
    resources :zombies
  end
end

# this way you will strip out the api part of the URI, removing duplication
# your URL will now look like this:
http://api.yourapp.com/zombies
# --------------------------------------------------------------------

# Using a shorter syntax for Constraints and Namespaces

# example:
# config\routes.rb
constraints subdomain: 'api' do
  namespace :api, path: '/' do
    resources :zombies
    resources :humans
  end
end

# or you can do this instead, they both output the same thing:

namespace :api, path: '/', constraints: {subdomain: 'api'} do
  resources :zombies
  resources :humans
end
# there are now less lines and characters you have to type.

# ----------------------------------------------------------------------
