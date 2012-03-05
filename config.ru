require 'rubygems'
require 'bundler'

Bundler.require


use Rack::Static, :root => 'public'
require './app'

run KeyMgmtServer
