$LOAD_PATH[0,0] = File.join(File.dirname(__FILE__), '..', 'lib')
require 'mongo'

include XGen::Mongo::Driver

host = ENV['MONGO_RUBY_DRIVER_HOST'] || 'localhost'
port = ENV['MONGO_RUBY_DRIVER_PORT'] || XGen::Mongo::Driver::Mongo::DEFAULT_PORT

puts "Connecting to #{host}:#{port}"
db = Mongo.new(host, port).db('ruby-mongo-examples-simple')
coll = db.collection('test')
coll.clear

3.times { |i| coll.insert({'a' => i+1}) }

puts "There are #{coll.count()} records in the test collection. Here they are:"
coll.find().each { |doc| puts doc.inspect }
