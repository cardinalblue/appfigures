require 'curb'
require 'json'

module AppFigures
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

    def usage
      begin
        handle_response(do_get(AppFigures::API::USAGE))
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    private

    def do_get(url)
      curl = Curl::Easy.new(url)
      curl.http_auth_types = :basic
      curl.headers['X-Client-Key'] = app_key
      curl.username = username
      curl.password = password
      curl.perform
      curl
    end

    def handle_response(curl)
      puts curl.headers
      puts curl.body
    end
  end
end