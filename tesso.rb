#!/usr/bin/ruby

$:.unshift('lib')

CONFIG = {
   :footer_note => 'some note',
   :footer_url => 'http://google.com/'
}

require 'sinatra'
require 'users'

enable :sessions

$users = nil

helpers do
   def get_users
      if $users == nil
         $users = Users.new
      end
      $users
   end
   def role?(user, rolestr)
      users = get_users
      u = users.find_by(user)
      u["role"] == rolestr
   end
   def admin?(session)
      return false if session[:user] == nil
      role?(session[:user], "admin")
   end
   def user?(session)
      return false if session[:user] == nil
      role?(session[:user], "user")
   end
   def room?(session)
      return false if session[:user] == nil
      role?(session[:user], "room")
   end
end

get '/' do
   redirect './login'
end

get '/hi' do
  'hi'
end

get '/login' do
   session.clear
   erb :login, :locals => { :constants => CONFIG }
end

post '/login' do
   users = Users.new
   if users.authenticate(params['user'], params['pass'])
      session[:user] = params['user']
      user = users.find_by(session[:user])
      if user["role"] == "admin"
         redirect './users'
      elsif user["role"] == "user"
         redirect './rooms'
      else
         redirect './files'
      end
   else
      @message = 'login failed.'
      erb :login, :locals => { :constants => CONFIG }
   end
end

get '/logout' do
   session.clear
   redirect './login'
end

get '/whoami' do
   if session[:user] == nil
      "not logged in."
   else
      users = Users.new
      user = users.find_by(session[:user])
      "your are '#{session[:user]}', role is #{user["role"]}"
   end
end

get '/users' do
   redirect './login' if !admin?(session)
   erb :users, :locals => { :users => get_users, :constants => CONFIG }
end

get '/user/new' do
   redirect '../login' if !admin?(session)
   erb :user_new, :locals => { :constants => CONFIG }
end

post '/user/new' do
   redirect '../login' if !admin?(session)
   get_users.add(params)
   redirect '../users'
end

get '/user/:uid/edit' do |uid|
   redirect '../../login' if !admin?(session)
   erb :user_edit, :locals => { :user => get_users.find_by(uid), :constants => CONFIG }
end

post '/user/:uid/edit' do |uid|
   redirect '../../login' if !admin?(session)
   get_users.edit(params)
   redirect '../../users'
end

get '/user/:uid/delete' do |uid|
   redirect '../../login' if !admin?(session)
   get_users.delete(uid)
   redirect '../../users'
end

get '/rooms' do
   if session[:user] == nil
      redirect './login'
   end
   users = Users.new
   if !users.user?(session[:user])
      redirect './login'
   end
   erb :rooms, :locals => { :users => users, :constants => CONFIG }
end
