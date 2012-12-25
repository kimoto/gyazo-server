#!/bin/env ruby
# encoding: utf-8
# Author: kimoto
require 'gyazo/filestore'
require 'digest/md5'
require 'httparty'
require 'uri'
require 'data-uri'

class GyazoServer < Sinatra::Base
  configure do
    set :image_dir, 'public/i'
    set :image_url_base_dir, '/i'
    set :digest_logic, Digest::MD5
  end

  get '/' do
    "Gyazo"
  end

  post '/' do
    save_to_filesystem request[:imagedata][:tempfile].read
  end

  get '/clone' do
    erb :clone
  end

  post '/clone' do
    url = params[:url].to_s
    if url =~ /^data:/
      data = DataURI.decode(url)
    else
      data = HTTParty.get(url).body
    end
    save_to_filesystem data
  end
  
  protected
  def save_to_filesystem(data)
    store = Gyazo::FileStore.new(settings.image_dir, :logic => settings.digest_logic, :compress => true)
    info = store.put(data)
    if info.already_exists?
      return 500
    else
      base_url = "#{request.scheme}://#{request.host_with_port}"
      path = File.join(settings.image_url_base_dir, info.fullpath)
      gyazo_url = URI.join(base_url, path).to_s
      return gyazo_url
    end
  end
end

