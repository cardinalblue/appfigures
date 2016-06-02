require 'appfigures/version'
require 'curb'
require 'json'

module AppFigures
  BASE_URL = 'https://api.appfigures.com/v2'

  class Client
    attr_accessor :username, :password, :app_key, :app_secret

    attr_writer :product_ids

    def initialize(username:, password:, app_key:, app_secret:)
      self.username   = username
      self.password   = password
      self.app_key    = app_key
      self.app_secret = app_secret
    end

    def add_product_id(key:, id:)
      product_ids.merge! key.to_sym => id.to_s
    end

    def product_ids
      @product_ids ||= {}
    end

    def product_keys
      product_ids.keys
    end
  end
end
