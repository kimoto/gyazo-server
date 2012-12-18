#!/bin/env ruby
# encoding: utf-8
# Author: kimoto
require 'digest/md5'
require 'fileutils'
require 'sinatra'
require 'uri'

module Gyazo
  class FileStore
    class FileInfo
      attr_accessor :path
      attr_accessor :dir
      attr_accessor :hexdigest
      attr_accessor :already_exist
      def fullpath
        File.join(@dir, @path)
      end
      def already_exists?
        @already_exist
      end
    end
    def initialize(base_path)
      @base_path = base_path
    end

    def put(data)
      raise ArgumentError if data.nil?
      hexdigest = Digest::MD5.hexdigest(data).to_s
      head_chars = hexdigest.each_byte.to_a.first(2).map(&:chr)

      info = FileInfo.new
      info.hexdigest = hexdigest
      info.dir = head_chars.join("/")
      info.path = "#{info.hexdigest}.png"

      store_dir = File.join(@base_path, info.dir)
      store_full_path = File.join(store_dir, info.path)
      FileUtils.mkdir_p(store_dir)

      if File.exists? store_full_path
        info.already_exist = true
        return info
      else
        info.already_exist = false
        File.write(store_full_path, data)
        return info
      end
    end
  end
end

configure do
  set :image_dir, 'public/i'
  set :image_url_base_dir, '/i'
end

get '/' do
  "Gyazo"
end

post '/' do
  data = request[:imagedata][:tempfile].read
  @info = Gyazo::FileStore.new(settings.image_dir).put(data)
  if @info.already_exists?
    500
  else
    base_url = "#{request.scheme}://#{request.host_with_port}"
    path = File.join(settings.image_url_base_dir, @info.fullpath)
    URI.join(base_url, path).to_s
  end
end

