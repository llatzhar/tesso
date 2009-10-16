#!/usr/bin/ruby

$:.unshift('lib')

CONFIG = {
   :footer_note => 'some note',
   :footer_url => 'http://google.com/'
}

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
   erb :login, :locals => { :constants => CONFIG }
end

get '/logout' do
   session.clear
   #cookie ||= 0
   redirect '/login'
end

post '/auth' do
   users = Users.new
   if users.authenticate(params['user'], params['pass'])
      session[:user] = params['user']
      redirect '/users'
   else
      @message = 'login faield.'
      erb :login, :locals => { :constants => CONFIG }
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
   # todo authorize
   erb :users, :locals => { :users => Users.new, :constants => CONFIG }
end

get '/user/new' do
   # todo authorize
   erb :user_new, :locals => { :constants => CONFIG }
end

post '/user/new' do
   # todo authorize
   users = Users.new
   users.add(params)
   
   redirect '/users'
end

get '/user/edit/:name' do
   # todo authorize
   erb :user_new, :locals => { :constants => CONFIG }
end

post '/user/edit/:name' do
   # todo authorize
   users = Users.new
   users.add(params)
   
   redirect '/users'
end

get '/user/delete/:name' do |n|
   # todo authorize
   users = Users.new
   users.delete(n)
   
   redirect '/users'
end
