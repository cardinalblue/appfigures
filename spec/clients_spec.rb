require 'spec_helper'
require 'yaml'

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
end
