#!/usr/bin/env ruby
# encoding: utf-8
# usage: ruby producer.rb [num_items]

require "bunny"				
error = true
while (error)
    sleep(1.0)
    begin
        @conn = Bunny.new("amqp://guest:guest@queue:5672")
        @conn.start							#will throw exception if unable to connect
        error = false
    rescue Bunny::TCPConnectionFailed
        puts "Retrying connection. Verify RabbitMQ server has started."
    end
end
ch = @conn.create_channel
q = ch.queue("main_queue", durable: true)	#declare queue, will be created if it doesn't exist
while(true)
    msg = (rand(20..45)).to_i.to_s			#generate number in 40..50
    q.publish(msg, persistent: true)
    puts " [x] Sent #{msg}"
    sleep(0.5)
end
@conn.close
