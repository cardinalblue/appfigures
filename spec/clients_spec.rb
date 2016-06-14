require 'spec_helper'
require 'yaml'
require 'json'

describe AppFigures::Client do

  context 'when initializing client' do
    it 'raises error with invalid parameters' do
      # username, password, app_key, app_secret
      [
        [nil, nil, nil, nil],
        [nil, nil, nil, 'd'],
        [nil, nil, 'c', nil],
        [nil, nil, 'c', 'd'],
        [nil, 'b', nil, nil],
        [nil, 'b', nil, 'd'],
        [nil, 'b', 'c', nil],
        [nil, 'b', 'c', 'd'],
        ['a', nil, nil, nil],
        ['a', nil, nil, 'd'],
        ['a', nil, 'c', nil],
        ['a', nil, 'c', 'd'],
        ['a', 'b', nil, nil],
        ['a', 'b', nil, 'd'],
        ['a', 'b', 'c', nil]
      ].each do |username, password, app_key, app_secret|
        expect{
          AppFigures::Client.new(username:   username,
                                 password:   password,
                                 app_key:    app_key,
                                 app_secret: app_secret)
        }.to raise_error(ArgumentError)
      end
    end

    it '.create' do
      expect(AppFigures::Client.new(username:   'me',
                                    password:   'secret',
                                    app_key:    'key',
                                    app_secret: 'not_telling')).not_to be nil
    end

  end

  context 'when manipulating product ids' do
    let(:config) { YAML.load_file('spec/config.example.yaml') }
    subject(:client) { AppFigures::Client.new(username:   config['username'],
                                              password:   config['password'],
                                              app_key:    config['app_key'],
                                              app_secret: config['app_secret']) }

    it '#add_product_ids with invalid argument' do
      [
        [nil, nil],
        [nil, 'b'],
        ['a', nil]
      ].each do |key, id|
        expect { client.add_product_id(key: key, id: id) }.to raise_error(ArgumentError)
      end
    end

    it '#add_product_ids successfully' do
      expect {
        client.add_product_id(key: 'key', id: 'id')
      }.to change { client.product_ids.length }.by(1)
    end

    it '#product_ids return type check' do
      client.add_product_id(key: 'key', id: 'id')
      expect(client.product_ids).to include(key: 'id')
    end

    it '#product_keys' do
      client.add_product_id(key: 'key', id: 'id')
      expect(client.product_keys).to include(:key)
    end

    it '#clear_product_ids' do
      client.add_product_id(key: 'key', id: 'id')
      expect { client.clear_product_ids }.to change { client.product_ids.length }.to(0)
    end
  end

  context 'when sending http request through #do_get' do
    let(:config) { YAML.load_file('spec/config.example.yaml') }
    subject(:client) { AppFigures::Client.new(username:   config['username'],
                                              password:   config['password'],
                                              app_key:    config['app_key'],
                                              app_secret: config['app_secret']) }
    before(:each) do
      @af = stub_request(:any, 'http://www.af.com')
    end

    it 'raises error with invalid parameter' do
      [nil, 'invalid uri', 'www.ruby-lang.org'].each do |url|
        expect { client.send(:do_get, url) }.to raise_error(ArgumentError)
      end
    end

    it 'invalid header' do
      @af.to_return(body: { content:'response' }.to_json,
                    status: 200,
                    headers: { 'Invalid header' => 1000, 'Wrong' => 10 })
      _, resp = client.send(:do_get, 'http://www.af.com')
      expect(resp).not_to be_nil
      expect(resp[:body]).not_to be_nil
      expect(resp).not_to have_key(:limit)
      expect(resp).not_to have_key(:usage)
    end

    it 'valid url, failed request(400)' do
      @af.to_return(body: { content:'response' }.to_json,
                    status: 400,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      _, resp = client.send(:do_get, 'http://www.af.com')
      expect(resp).not_to be_nil
      expect(resp).not_to have_key(:body)
      expect(resp[:limit]).to eq(1000)
      expect(resp[:usage]).to eq(10)
    end

    it 'successful request(200), invalid body (not json)' do
      @af.to_return(body: 'response',
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      _, resp = client.send(:do_get, 'http://www.af.com')
      expect(resp).not_to be_nil
      expect(resp[:body]).to be_nil
      expect(resp[:limit]).to eq(1000)
      expect(resp[:usage]).to eq(10)
    end

    it 'successful request(200)' do
      @af.to_return(body: { content:'response' }.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      _, resp = client.send(:do_get, 'http://www.af.com')
      expect(resp).not_to be_nil
      expect(resp[:body]).not_to be_nil
      expect(resp[:limit]).to eq(1000)
      expect(resp[:usage]).to eq(10)
    end
  end

  context '#do_get specific AppFigure calls' do
    let(:config) { YAML.load_file('spec/config.example.yaml') }
    subject(:client) { AppFigures::Client.new(username:   config['username'],
                                              password:   config['password'],
                                              app_key:    config['app_key'],
                                              app_secret: config['app_secret']) }
    before(:each) do
      @af = stub_request(:any, /#{AppFigures::API::BASE_URL}\/*/)
      @date = '2016-01-01'
      client.add_product_id(key: 'key', id: 123)
    end

    it 'returns valid body with #usage' do
      body = { 'usage'=>10 }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.usage
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'returns valid body with #products' do
      body = { 'id'=> 123, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.products
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'valid id with #products' do
      body = { 'id'=> 123, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.products(id = 123)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid id with #products' do
      body = { 'id'=> 1234567, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      expect{ client.products(id = 1234567) }.to raise_error(ArgumentError)
    end

    it 'return valid body with #sales' do
      body = { 'id'=> 123, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.sales
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #revenue' do
      body = { 'id'=> 123, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.revenue
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with  #ads' do
      body = { 'id'=> 123, 'name'=>'myapp' }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.ads
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #rank' do
      body = { 'rank'=> 15 }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp = client.ranks(ids: 123)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameters for #rank (missing id)' do
      body = { 'rank'=> 15 }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      expect{ client.ranks }.to raise_error(ArgumentError)
    end

    it 'invalid mode for #featured' do
      expect{ client.featured(mode: :invalid_mode) }.to raise_error(ArgumentError)
    end

    it 'return valid body with #featured summary' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.featured(start_date: @date, end_date: @date)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameters for #featured summary' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      [
        [nil,   nil],
        [nil,   @date],
        [@date, nil],
      ].each do |start, end_date|
        expect{
          client.featured(mode: :summary, start_date: start, end_date: end_date)
        }.to raise_error(ArgumentError)
      end
    end

    it 'return valid body with #featured full' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.featured(mode: :full, start_date: @date, end_date: @date, product_id: 123)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameters for #featured full' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      [
        [nil,   nil ,  0],
        [nil,   nil ,  123],
        [nil,   @date, 0],
        [nil,   @date, 123],
        [@date, nil,   0],
        [@date, nil,   123],
        [@date, @date, 0],
        [@date, @date, 012]
      ].each do |start, end_date, id|
        expect{
          client.featured(mode: :full, start_date: start, end_date: end_date, product_id: id)
        }.to raise_error(ArgumentError)
      end
    end

    it 'return valid body with #featured counts' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10} )
      resp =  client.featured(mode: :counts, args: {end: @date})
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameter for #featured counts' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10} )
      expect{ client.featured(mode: :counts) }.to raise_error(ArgumentError)
    end

    it 'return valid body with #featured history' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.featured(mode: :history, product_id: 123, featured_category_id: 456)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameters for #featured history' do
      body = { 'id'=> 123, 'paths'=> %w(apple free handheld) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      [
        [0,   0],
        [0,   123],
        [123, 0],
        [012, 012]
      ].each do |id, fc_id|
        expect{
          client.featured(mode: :history, product_id: id, featured_category_id: fc_id)
        }.to raise_error(ArgumentError)
      end
    end

    it 'return valid body with #reviews' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.reviews
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #reviews count' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.reviews(mode = :count)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid mode for #reviews' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      expect{ client.reviews(mode = :invalid_mode) }.to raise_error(ArgumentError)
    end

    it 'return valid body with #ratings' do
      body = { 'id'=> 123, 'ratings' => 10 }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.ratings
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #get_events' do
      body = { 'id'=> 123, 'events'=> %w(ev1 ev2 ev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.get_events
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #archive' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.archive
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #archive latest' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.archive(mode = :latest)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'return valid body with #archive raw' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.archive(mode = :raw, id = 123)
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameter for #archive raw (missing id)' do
      body = { 'id'=> 123, 'reviews'=> %w(rev1 rev2 rev3) }
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      expect{ client.archive(mode = :raw) }.to raise_error(ArgumentError)
      expect{ client.archive(mode = :raw, id = 012) }.to raise_error(ArgumentError)
    end

    it 'return valid body with #users' do
      body = { 'user id'=> 123}
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      resp =  client.users(email = 'my_email')
      expect(resp).not_to be_nil
      expect(resp).to include(body)
    end

    it 'invalid parameter for #users (invalid email)' do
      body = { 'user id'=> 123}
      @af.to_return(body: body.to_json,
                    status: 200,
                    headers: { 'X-Request-Limit' => 1000, 'X-Request-Usage' => 10 })
      expect{ client.users }.to raise_error(ArgumentError)
    end

  end
end
