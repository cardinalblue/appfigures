$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'appfigures'
require 'webmock/rspec'

# spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

#disable all net connections except localhost
WebMock.disable_net_connect!(:allow_localhost => true)
