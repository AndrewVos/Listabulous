require File.join(File.dirname(__FILE__), '..', 'listabulous.rb')

require 'rubygems'
require 'sinatra'

set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

require 'rack/test'
require 'rspec'
# require 'spec/autorun'
# require 'spec/interop/test'
require 'mongo_mapper'
require 'pony'
require 'email'
require 'active_support/secure_random'

MongoMapper.database = "ListabulousTest"

ENV["COOKIE_ENCRYPTION_KEY"] = "\022\032\361\306|\225\206\204\242\202\262\025e>j2I\021\222[r\334\305H\250\334\003k\201\366~S"
ENV["COOKIE_ENCRYPTION_IV"] = "+\325\310;^\031d\237\243_\336\356\235\203\3525"

module Rack
  module Test
    DEFAULT_HOST = "www.listabulous.co.uk"  
  end
end