#!/bin/env ruby
# encoding: utf-8
# Author: kimoto
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

    def initialize(base_path, opts={})
      @base_path = base_path
      @logic = opts[:logic] || lambda { |data| Digest::MD5.hexdigest(data).to_s }
      @ext = opts[:ext]
      @opts = opts
    end

    def put(data)
      raise ArgumentError if data.nil?
      hexdigest = @logic.call(data)
      info = FileInfo.new
      info.hexdigest = hexdigest
      info.dir = "./"
      info.path = "#{info.hexdigest}.#{@ext}"

      store_dir = File.join(@base_path, info.dir)
      store_full_path = File.join(store_dir, info.path)
      FileUtils.mkdir_p(store_dir)

      if File.exists? store_full_path
        info.already_exist = true
        return info
      else
        info.already_exist = false
        File.write(store_full_path, data)
        if @opts[:compress]
          system("pngquant --ext '_C.png' --force 256 #{store_full_path}")
          info.path = "#{info.hexdigest}_C.png"
        end
        return info
      end
    end
  end
end


