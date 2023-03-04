require 'json'
require 'uri'
require 'net/http'

def get(uri, &block)
    yield Net::HTTP.get_response URI("http://localhost:8080#{uri}")
end

get "/" do |r|
    abort unless r.is_a? Net::HTTPSuccess
    entities = JSON.parse r.body
    p entities
end