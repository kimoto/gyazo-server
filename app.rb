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
    set :resized_image_dir, 'public/r'
    set :image_url_base_dir, '/i'
    set :resized_image_url_base_dir, '/r'
  end

  # copied from http://lokka.kksg.net/bitly
  # class methods
  @@table = [
    ('0' .. '9'), ('a' .. 'z'),
    ('A' .. 'Z')
    #  ('A' .. 'Z'), ["-", "_"]
  ].map(&:to_a).flatten.freeze
  @@random_range = 256 ** 4

  def conv64(i)
    digit = []
    begin
      i, c = i.divmod(62)
      digit << @@table[c+1]
    end while i > 0
    return digit.reverse.join('')
  end

  def gen_random_digest
    conv64(rand(@@random_range))
  end

  # 元の画像URL + /i/AaAa.png/48x48 みたいなフォーマット
  # 画像をリサイズしてその静的ファイルへリダイレクトしてくれるやつ
  get %r{^/i/([\w]+).png/(\d+)x(\d+)$} do |image_id, width, height|
    if (width > 1024 or height > 1024) or (width <= 0 or height <= 0)
      raise ArgumentError.new("illegal width/height size specified")
    end
    image_path = File.join(settings.resized_image_dir, image_id + "_#{width}x#{height}" + ".png") # resized png full path
    resized_image_url = File.join(settings.resized_image_url_base_dir, image_id + "_#{width}x#{height}.png")
    content_type 'image/png'
    if File.exists?(image_path)
      redirect resized_image_url
    else
      # なかったら作る
      orig_path = File.join(settings.image_dir, image_id + ".png")
      pid = spawn("convert -resize #{width}x#{height} #{orig_path} #{image_path}") # 出力先
      Process.waitpid(pid)
      File.read(image_path)
      redirect resized_image_url
    end
  end

  get '/' do
    "Gyazo"
  end

  post '/' do
    if request[:data]
      save_to_filesystem request[:data][:tempfile].read, "mp4" # gifzoのときはこっち
    else
      save_to_filesystem request[:imagedata][:tempfile].read, "png" # gyazoのときはこっち
    end
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
  def save_to_filesystem(data, ext)
    store = Gyazo::FileStore.new(settings.image_dir, :logic => lambda{ |data| gen_random_digest}, :ext => ext)
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

