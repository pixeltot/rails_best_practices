
# 1. install paperclip for avatars, Use paperclip to upload files
# -----------------------------------------------------------------
gem 'paperclip', '~> 4.2'
# use babosa for url normalize
gem 'babosa'
# run bundle
$ bundle install


# 2. create a Profile Model
# -------------------------
$ rails g model Profile user:belongs_to name:string cid:string birthday:date sex:string tel:string address:string tagline:string introduction:text avatar:attachment --no-timestamps
$ rake db:migrate


# 3. Model
# ----------
# app\models\profile.rb
class Profile < ActiveRecord::Base
  belongs_to :user

  has_attached_file :avatar, styles: { medium: '300x300>', thumb: '100x100>' },
                             url: '/system/:class/:attachment/:id_partition/:style/:hash.:extension',
                             path: ':rails_root/public/system/:class/:attachment/:id_partition/:style/:hash.:extension',
                             hash_secret: '<get_use_rake_secret>'
  validates_attachment :avatar, content_type: { content_type: /\Aimage\/.*\Z/ },
                                size: { in: 0..1.megabytes }
end

# app\models\user.rb
 ...
  has_one :profile, dependent: :destroy
  accepts_nested_attributes_for :profile
  ...
  def username
    self.email.split(/@/).first
  end

  def to_param
    "#{id} #{username}".to_slug.normalize.to_s
  end
  ...


# 4. Routes
# ----------
# config\routes.rb
 ...
  get ':id' => 'users#show', as: :user_profile
  get ':id/setting' => 'users#edit', as: :user_setting
  match ':id/setting' => 'users#update', via: [:put, :patch]
  ...


# 5.Controller
# ------------
# app/controllers/users_controller.rb
# authenticate_owner!
class UsersController < ApplicationController
  before_action :authenticate_owner!
  before_filter :set_user, only: [:show, :edit, :update]

  def show
  end

  def edit
    @user.build_profile if @user.profile.nil?
  end

  def update
    if @user.update(user_params)
      redirect_to user_profile_path(@user)
    else
      render 'edit'
    end
  end

  private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(profile_attributes: [:id, :name, :cid, :birthday, :sex, :tel, :address, :tagline, :introduction, :avatar])
    end

    def authenticate_owner!
      redirect_to root_path unless user_signed_in? && current_user.to_param == params[:id]
    end
end


# 5. View
# -------
# Edit Form
# app\views\users\edit.html.haml
.container
  .page-header
    %h3
      = t :user_setting
  = render partial: 'users/form', locals: { resource: @user }

# app\views\users\_form.html.haml
= bootstrap_form_for resource, url: user_setting_path, html: { multipart: true }, layout: :horizontal, label_col: 'col-sm-2', control_col: 'col-sm-4' do |f|
  = f.static_control :email
  = f.fields_for :profile do |n|
    = n.text_field :name, autofocus: true
    = n.text_field :cid
    = n.date_field :birthday
    = n.select :sex, [[t(:male), 'male'], [t(:female), 'female']], prompt: true
    = n.text_field :tel
    = n.text_field :address, control_col: 'col-sm-6'
    = n.text_field :tagline, control_col: 'col-sm-6'
    = n.text_area :introduction, control_col: 'col-sm-6'
    = n.file_field :avatar
  = f.form_group do
    = f.primary t(:update)
    = link_to t(:cancel), user_profile_path(current_user), class: 'btn btn-default'

# Show Page
# app\views\users\show.html.haml
- # sex use locales
= t(@user.profile.sex)
- # avatar url
= link_to 'original', @user.profile.avatar.url, target: '_blank'
= link_to 'medium', @user.profile.avatar.url(:medium), target: '_blank'
= link_to 'thumb', @user.profile.avatar.url(:thumb), target: '_blank'

# 6. Locales
# ----------
# config\locales\model.user.zh-TW.yml
zh-TW:
  helpers:
    label:
      user:
        email: '信箱'
        password: '密碼'
        password_confirmation: '密碼確認'
        current_password: '目前密碼'
        remember_me: '保持登入狀態'
        remember_created_at: '保持登入狀態開始時間'
        sign_in_count: '登入次數'
        current_sign_in_at: '登入時間'
        last_sign_in_at: '上次登入時間'
        current_sign_in_ip: '登入IP'
        last_sign_in_ip: '上次登入IP'
        created_at: '建立時間'
        updated_at: '更新時間'
  help:
    user:
      change_password: '需要您目前密碼來完成變更'

# config\locales\model.profile.zh-TW.yml
zh-TW:
  helpers:
    label:
      profile:
        name: '姓名'
        cid: '身分證'
        birthday: '生日'
        sex: '性別'
        tel: '聯絡電話'
        address: '地址'
        tagline: '座右銘'
        introduction: '關於我'
        avatar_file_name: '頭像檔案名稱'
        avatar_content_type: '頭像檔案類型'
        avatar_file_size: '頭像檔案大小'
        avatar_updated_at: '頭像上傳時間'
        avatar: '頭像'
  # sex
  male: '男'
  female: '女'
