#!/usr/bin/ruby

$:.unshift('lib')

$CONFIG = {
   :footer_note => 'some note',
   :footer_url => 'http://google.com/',
   :users => 'users.yml',
   :rooms => 'rooms.yml'
}

require 'sinatra'
require 'users'

enable :sessions

$users = nil

helpers do
   def role?(user, rolestr)
      users = Users.instance($CONFIG[:users])
      u = users.find(user)
      return false if u == nil
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
      rooms = Rooms.instance($CONFIG[:rooms])
      return rooms.find(session[:user]) != nil
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
   erb :login, :locals => { :constants => $CONFIG }
end

post '/login' do
   room = Rooms.instance($CONFIG[:rooms]).authenticate(params['user'], params['pass'])
   if room != nil
      session[:user] = params['user']
      redirect "./#{room["id"]}"
   else
      users = Users.instance($CONFIG[:users])
      user = users.authenticate(params['user'], params['pass'])
      if user != nil
         session[:user] = params['user']
         #user = users.find(session[:user])
         if user["role"] == "admin"
            redirect './users'
         elsif user["role"] == "user"
            redirect './rooms'
         end
      end
   end
   @message = 'login failed.'
   erb :login, :locals => { :constants => $CONFIG }
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
   erb :users, :locals => {
      :users => Users.instance($CONFIG[:users]),
      :constants => $CONFIG
   }
end

get '/user/new' do
   redirect '../login' if !admin?(session)
   erb :user_new, :locals => {
      :constants => $CONFIG
   }
end

post '/user/new' do
   redirect '../login' if !admin?(session)
   Users.instance($CONFIG[:users]).add(params)
   redirect '../users'
end

get '/user/:uid/edit' do |uid|
   redirect '../../login' if !admin?(session)
   
   erb :user_edit, :locals => {
      :user => Users.instance($CONFIG[:users]).find(uid),
      :constants => $CONFIG
   }
end

post '/user/:uid/edit' do |uid|
   redirect '../../login' if !admin?(session)
   Users.instance($CONFIG[:users]).edit(params)
   redirect '../../users'
end

get '/user/:uid/delete' do |uid|
   redirect '../../login' if !admin?(session)
   Users.instance($CONFIG[:users]).delete(uid)
   redirect '../../users'
end

get '/rooms' do
   redirect './login' if !user?(session)
   rooms = Rooms.instance($CONFIG[:rooms])
   
   #TODO cannot call h, u method(erb).
   erb :rooms, :locals => {
      :user => Users.instance($CONFIG[:users]).find(session[:user]),
      :rooms => rooms,
      :constants => $CONFIG
   }
end

get '/room/new' do
   redirect '../login' if !user?(session)
   erb :room_new, :locals => {
      :constants => $CONFIG
   }
end

post '/room/new' do
   redirect '../login' if !user?(session)
   Rooms.instance($CONFIG[:rooms]).add(params)
   redirect '../rooms'
end

get '/:roomid' do |roomid|
   redirect './login' if !user?(session) and !room?(session)
   room = Rooms.instance($CONFIG[:rooms]).find(roomid)
   erb :files, :locals => {
      :room => room,
      :constants => $CONFIG
   }
end

get '/:roomid/edit' do |roomid|
   redirect '../login' if !user?(session)
   
   erb :room_edit, :locals => {
      :room => Rooms.instance($CONFIG[:rooms]).find(roomid),
      :constants => $CONFIG
   }
end

post '/:roomid/edit' do |roomid|
   redirect '../login' if !user?(session)
   Rooms.instance($CONFIG[:rooms]).edit(params)
   redirect '../rooms'
end

get '/:roomid/delete' do |roomid|
   redirect '../login' if !user?(session)
   Rooms.instance($CONFIG[:rooms]).delete(roomid)
   redirect '../rooms'
end