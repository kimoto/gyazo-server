#!/bin/env ruby
# encoding: utf-8
# Author: kimoto
require 'gyazo/filestore'
require 'digest/md5'

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
    data = request[:imagedata][:tempfile].read
    @info = Gyazo::FileStore.new(settings.image_dir, :logic => settings.digest_logic, :compress => true).put(data)
    if @info.already_exists?
      500
    else
      base_url = "#{request.scheme}://#{request.host_with_port}"
      path = File.join(settings.image_url_base_dir, @info.fullpath)
      URI.join(base_url, path).to_s
    end
  end
end

