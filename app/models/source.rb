class Source < ApplicationRecord

  def self.providers
    self.subclasses
  end

  def self.provider_names
    self.subclasses.map{|c| c.name}
  end

  def self.nice_name
    self.name
  end

  belongs_to :user, :class_name => "User", :foreign_key => "user_id"
  has_many :requests, dependent: :delete_all

  validates_associated :user
  serialize :data, JSON
  # validates_inclusion_of :type, :in => Source.provider_names, :on => :create, :message => "Invalid provider"

  after_create :create_default_requests

  def self.from_omniauth(auth)
    where(auth.slice("provider", "uid")).first || create_from_omniauth(auth)
  end

  # This is from the omniauth callback
  def self.create_from_omniauth(auth)
    raise ActionController::BadRequest unless self.AUTH_TYPE == :oauth
    create! do |source|
      source.provider = auth["provider"]
      source.uid = auth["uid"]
      source.data = auth
    end
  end

  def create_default_requests
  end

  def doc_url
    nil
  end

  def auth_type
    self.class::AUTH_TYPE
  end
  def provider_name
    self.class.nice_name
  end


  def public_data
    self.auth_type == :oauth ? self.data : nil
  end

  def public_info
    self.auth_type == :oauth ? self.data["info"] : nil
  end

  def expire_at
    nil
  end
  def expired?
    self.expire_at.nil? ? false : (self.expire_at < DateTime.now.to_i)
  end
end

# In development classes are loaded and reloaded on demand and we need to make
# sure that all subclasses are loaded. In production everything is pre-loaded.
if Rails.env.development?
  Dir["#{Rails.root}/app/models/sources/*.rb"].each do |p|
    require_dependency p
  end
end
