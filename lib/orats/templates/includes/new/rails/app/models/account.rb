class Account < ActiveRecord::Base
  ROLES = %w[admin guest]

  devise :database_authenticatable, :registerable, :recoverable, :rememberable,
         :trackable, :timeoutable, :lockable, :validatable, :async

  before_validation :ensure_password, on: :create

  after_save :invalidate_cache

  validates :role, inclusion: {in: ROLES}

  def self.serialize_from_session(key, salt)
    # store the current_account in the cache so we do not perform a db lookup on each authenticated page
    single_key = key.is_a?(Array) ? key.first : key

    Rails.cache.fetch("account:#{single_key}") do
      Account.where(id: single_key).entries.first
    end
  end

  def self.generate_password(length = 10)
    Devise.friendly_token.first(length)
  end

  def is?(role_check)
    role.to_sym == role_check
  end

  private

  def ensure_password
    # only generate a password if it does not exist
    self.password ||= Account.generate_password
  end

  def invalidate_cache
    Rails.cache.delete("account:#{id}")
  end
end