require 'spec_helper'

describe AppFigures::Client do
  it 'should raise error with invalid parameters' do
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
