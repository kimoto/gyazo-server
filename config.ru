$LOAD_PATH << File.join(File.dirname(__FILE__), "lib")
require 'sinatra'
require './app'
run Sinatra::Application
