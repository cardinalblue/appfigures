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

    # Get product info from AppFigures
    # See http://docs.appfigures.com/products for details
    # Note:
    # - AppFigures#products does not support search
    # - optional to add product id as parameter

    def products(id = 0, args = {})
      url = AppFigures::API::PRODUCTS
      if @product_ids.has_value?(id.to_s)
        url += "/#{id}"
      else
        raise ArgumentError.new('Invalid product ID') if id > 0
      end
      begin
        _, resp = do_get(url, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get sales info from Appfigures
    # See http://docs.appfigures.com/api/reference/v2/sales for details

    def sales(args = {})
      begin
        _, resp = do_get(AppFigures::API::SALES, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get revenue info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/revenue for details
    def revenue(args = {})
      begin
        _, resp = do_get(AppFigures::API::REVENUE, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get ads info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/ads for details

    def ads(args = {})
      begin
        _, resp = do_get(AppFigures::API::ADS, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get ranking info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/ranks for details
    # #ranks parameters:
    # - ids: required, separate multiple product ids with ;
    # - granularity: either hourly or daily, default daily
    # - start/end dates: in format yyyy-MM-dd, default one day ago to now

    def ranks(ids, granularity= 'daily', start_date= days_ago, end_date= days_ago, args= {})
      url = "#{AppFigures::API::RANKS}/#{ids}/#{granularity}/
            #{start_date.strftime(PARAM_DATE_FORMAT)}/#{end_date.strftime(PARAM_DATE_FORMAT)}"
      begin
        _, resp = do_get(url, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get info on featured products from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/featured for details
    # #featured parameters:
    # - mode: summary, full, counts or history, as symbols; default is summary
    # - summary: start_date, end_date                 (required)
    # - full:    start_date, end_date, product_id     (required)
    # - counts:  end_date in args                     (required)
    # - history: product_id, featured_category_id     (required)

    def featured(mode: :summary, start_date: nil , end_date: nil, product_id: 0, featured_category_id: 0, args: {})
      url = AppFigures::API::FEATURED + "/#{mode}"
      case mode
      when :summary
        raise ArgumentError.new('Missing date') if start_date.nil? || end_date.nil?
        url += "/#{start_date}/#{end_date}"
      when :full
        raise ArgumentError.new('Missing date') if start_date.nil? || end_date.nil?
        raise ArgumentError.new('Missing product_id') if !@product_ids.has_value?(product_id.to_s)
        url += "/#{product_id}/#{start_date}/#{end_date}"
      when :counts
        raise ArgumentError.new('Missing end date') unless args.has_key?(:end)
      when :history
        raise ArgumentError.new('Missing id') if featured_category_id == 0 || !@product_ids.has_value?(product_id.to_s)
        url += "/#{product_id}/#{featured_category_id}"
      else
        raise ArgumentError.new("Invalid mode: #{mode.to_s}")
      end
      begin
        _, resp = do_get(url, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get reviews info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/reviews for details
    # #reviews parameters:
    # - mode: no input or :count (as symbol)

    def reviews(mode: nil, args: {})
      case mode
      when nil, '', '/'
        url = AppFigures::API::REVIEWS
      when :count
        url = AppFigures::API::REVIEWS + '/count'
      else
        raise ArgumentError.new("Invalid mode: #{mode.to_s}")
      end
      begin
        _, resp = do_get(url, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get ratings info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/ratings for details

    def ratings(args = {})
      begin
        _, resp = do_get(AppFigures::API::RATINGS, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get events from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/events for details
    # Note: #get_events does not support POST, PUT, and DELETE

    def get_events(args = {})
      begin
        _, resp = do_get(AppFigures::API::EVENTS, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get archived (raw) report data from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/archive for details
    # #archive parameters:
    # - mode: no input, :latest, or :raw (as symbols)
    # - id: product id, only required for raw mode

    def archive(mode: nil, id: 0, args: {})
      url = AppFigures::API::ARCHIVE
      case mode
      when nil, '', '/'
      when :latest
        url += '/latest/'
      when :raw
        raise ArgumentError.new("Invalid id: #{id}") if !@product_ids.has_value?(id.to_s)
        url += "/raw/#{id}/"
      else
        raise ArgumentError.new("Invalid mode: #{mode.to_s}")
      end
      begin
        _, resp = do_get(url, args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    # Get user info from AppFigures
    # See http://docs.appfigures.com/api/reference/v2/users for details
    # #users parameters:
    # - email required

    def users(email = nil, args = {})
      raise ArgumentError.new("Invalid email: #{email}") if email.nil?
      begin
        _, resp = do_get(AppFigures::API::USERS + "/#{email}", args)
        resp
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end

    private

    def do_get(url, args = {})
      raise ArgumentError.new("Invalid url: #{url}") unless url =~ URI::regexp
      response = {}
      curl = Curl::Easy.new(Curl::urlalize(url, args)) do |c|
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
      response[:code] = curl.response_code.to_i
      [curl, response]
    end

    def days_ago(days = 1)
      Time.now - (days * 86400)
    end

  end
end