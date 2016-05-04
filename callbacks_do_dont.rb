# AVOID CALLING OTHER DOMAIN OBJECTS FROM CALBACKS
# CALLBACKS ARE METHODS THAT GET CALLED AT CERTAIN MOMENTS OF AN OBJECT'S LIFE CYCLE

# DONT!
# ------

# app\models\user.rb
class User < ActiveRecord::Base
  before_create :set_token

  protected
    def set_token
      self.token = TokenGenerator.create(self)
    end
end

# HERES WHY YOU DONT WANT TO DO THIS...
# ------------------------------------------
# the set_token method is going to be called
# which depends on the TokenGenerator model
# the problem is that the TokenGenerator model is going to be called
# everytime we try to create a new user record which depends on the TokenGenerator model
# REFERENCING ANOTHER MODEL IN A CALLBACK INTRODUCES TIGHT COUPLING
# this affects the object's database lifecycle
# if the TokenGenerator model raises an error, the user will not be saved

#---------------------------------------------------

# DO THIS AS A WORKAROUND!
# we can fix this by creating a new method on the User model (class User)
# we call this method register, but it can be called anything you want
# inside this method we are going to assign a new token
# using our TokenGenerator class in the create method, and then we save the user record

# app\models\user.rb
class User < ActiveRecord::Base
  def register
    self.token = TokenGenerator.create(self)
    save
  end
end

# then inside of the controller we call the register method
# this is better because the TokenGenerator is de-coupled from the object database lifecycle

# app\controllers\users_controller.rb
class UserController < ApplicationController
  def create
    @user = User.new(user_params)
    if @user.register
      redirect_to @user, notice: 'Successfully registered'
    else
      ...
    end

  end
end

# CALLBACKS SHOULD ONLY BE USED FOR MODIFYING THE INTERNAL STATE OF THE OBJECT
# THE INTERNAL STATE OF THE MODEL
# FOR EXAMPLE:

# app\model\user.rb
class User < ActiveRecord::Base
  before_create :set_name

  protected
    def set_name
      self.name = self.login.capitalize if name.blank?
    end
end

# the set_name method sets the name property on the user based on its login
# if the name is not already set
# ITS ALSO A CONVENTION TO SET YOUR CALLBACKS AS PROTECTED
# notice that this callback doesnt have any external dependencies (other models)
# it all happends within the user model
