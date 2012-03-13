require 'rubygems'
require 'bundler'
require 'webrick'
require 'webrick/https'
require 'openssl'

Bundler.require

topdir = File.expand_path(File.dirname(__FILE__) + "/..")

puts topdir

$LOAD_PATH.unshift(topdir) unless $LOAD_PATH.include?(topdir)

use Rack::Static, :root => "#{$LOAD_PATH}/public"

require "#{topdir}/app/app"

# HTTPS config for webrick from
# http://stackoverflow.com/questions/3696558/how-to-make-sinatra-work-over-https-ssl
CERT_PATH = "#{topdir}/certs/"
webrick_options = {
    :Port               => 8443,
    :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
    :DocumentRoot       => "#{topdir}/public",
    :SSLEnable          => true,
    :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
    :SSLCertificate     => OpenSSL::X509::Certificate.new(File.open(File.join(
        CERT_PATH, "server.crt")).read),
    :SSLPrivateKey      => OpenSSL::PKey::RSA.new(
        File.open(File.join(CERT_PATH, "server.key")).read),
    :SSLCertName        =>  [ [ "CN",WEBrick::Utils::getservername ] ],
    :app                => KeyMgmtServer
}

Rack::Server.start(webrick_options)
