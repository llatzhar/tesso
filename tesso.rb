#!/usr/bin/ruby

$:.unshift('lib')

require 'sinatra'
require 'users'

enable :sessions

get '/' do
   redirect '/login'
end

get '/hi' do
  'hi'
end

get '/login' do
   session.clear
   erb :login
end

get '/logout' do
   session.clear
   cookie ||= 0
   redirect '/login'
end

post '/auth' do
   users = Users.new
   if users.authenticate(params['user'], params['pass'])
      session[:user] = params['user']
      redirect '/users'
   else
      @message = 'login faield.'
      erb :login
   end
end

get '/whoami' do
   if session[:user] == nil
      "not logged in."
   else
      "your are '#{session[:user]}'"
   end
end

get '/users' do
   erb :users, :locals => { :users => Users.new }
end


