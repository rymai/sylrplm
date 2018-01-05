# frozen_string_literal: true

# config/unicorn.rb
require 'rails'

# 5 mn
timeout 300
preload_app true
puts "#{__FILE__} ======================== #{Rails.env}"
nbproc = 0
if Rails.env == 'development'
  nbproc = 1
  listen '0.0.0.0:3000' # listen to port 3000 on the loopback interface
elsif Rails.env == 'test'
  nbproc = 1
elsif Rails.env == 'production'
  nbproc = 3
end
if ENV['WEB_CONCURRENCY'].blank?
  worker_processes nbproc
else
  worker_processes Integer(ENV['WEB_CONCURRENCY'])
end

before_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |_server, _worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  defined?(ActiveRecord::Base) &&
    ActiveRecord::Base.establish_connection
end
