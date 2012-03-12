require 'rubygems'
require 'bundler'

Bundler.require

topdir = File.expand_path(File.dirname(__FILE__) + "/..")

puts topdir

$LOAD_PATH.unshift(topdir) unless $LOAD_PATH.include?(topdir)

use Rack::Static, :root => "#{$LOAD_PATH}/public"

require "#{topdir}/app/app"

run KeyMgmtServer
