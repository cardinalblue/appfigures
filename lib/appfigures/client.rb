require 'curb'
require 'json'
require 'uri'

module AppFigures
  class Client
    attr_accessor :username, :password, :app_key, :app_secret

    attr_writer :product_ids

    def initialize(username:, password:, app_key:, app_secret:)
      if username.nil? or password.nil? or app_key.nil? or app_secret.nil?
        raise ArgumentError.new('Arguments cannot be nil. (%s, %s, %s, %s)' %
                                [username.inspect, password.inspect, app_key.inspect, app_secret.inspect])
      end

      self.username   = username
      self.password   = password
      self.app_key    = app_key
      self.app_secret = app_secret
    end

    def add_product_id(key:, id:)
      if key.nil? or id.nil?
        raise ArgumentError.new('Arguments cannot be nil. (%s, %s)' % [key.inspect, id.inspect])
      end

      product_ids.merge! key.to_sym => id.to_s
    end

    def clear_product_ids
      product_ids.clear
    end

    def product_ids
      @product_ids ||= {}
    end

    def product_keys
      product_ids.keys
    end

    def usage
      begin
        _, resp = do_get(AppFigures::API::USAGE)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    def ranks(args = {})
      begin
      _, resp = do_get(API::RANKS)
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end

    end

    private

    def do_get(url)
      raise ArgumentError.new("Invalid url: #{url}") unless url =~ URI::regexp
      response = {}
      curl = Curl::Easy.new(url) do |c|
        c.on_header do |header|
          if header.start_with?('X-Request-Limit:')
            response[:limit] = header.split.last.to_i
          elsif header.start_with?('X-Request-Usage:')
            response[:usage] = header.split.last.to_i
          end
          header.length
        end
        c.on_success do |easy|
          response[:body] = JSON.parse(easy.body) rescue nil
        end
        c.http_auth_types = :basic
        c.headers['X-Client-Key'] = app_key
        c.username = username
        c.password = password
      end
      curl.perform

      [curl, response]
    end

  end
end