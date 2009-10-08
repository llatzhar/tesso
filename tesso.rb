#!/usr/bin/ruby

$:.unshift('lib')

require 'sinatra'
require 'users'

enable :sessions

get '/hi' do
  'hi'
end

get '/login' do
   erb :login
end

post '/auth' do
   users = Users.new
   if users.authenticate(params['user'], params['pass'])
      session[:user] = params['user']
      redirect '/tesso2/users'
   else
      @message = 'login faield.'
      erb :login
   end
end

get '/bar' do
   session[:user]
end

get '/users' do
   erb :users
end


