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
      @logic = opts[:logic] || Digest::MD5
      @opts = opts
    end

    def put(data)
      raise ArgumentError if data.nil?
      hexdigest = @logic.hexdigest(data).to_s
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
        if @opts[:compress]
          system("pngquant --ext '_C.png' --force 256 #{store_full_path}")
          info.path = "#{info.hexdigest}_C.png"
        end
        return info
      end
    end
  end
end


