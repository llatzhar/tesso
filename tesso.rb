#!/usr/bin/ruby

$CONFIG = {
   :files_dir => 'd:\\',
   :temp_dir => '/temp',
   :footer_note => 'some note',
   :footer_url => 'http://google.com/',
   :users => 'users.yml',
   :rooms => 'rooms.yml',
   :files => 'files.yml'
}

$:.unshift('lib')

if $CONFIG.key?(:temp_dir)
   ENV['TMPDIR'] = $CONFIG[:temp_dir]
end

require 'sinatra'
require 'users'

enable :sessions

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
   
   def room?(session, roomid)
      return false if session[:user] == nil
      rooms = Rooms.instance($CONFIG[:rooms])
      room = rooms.find(session[:user])
      (room != nil) and (room["id"] == roomid)
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

get '/:roomid/:fileid/delete' do |roomid, fileid|
   redirect '../../login' if !user?(session) and !room?(session, roomid)
   
   id = fileid.to_i
   
   # file
   filename = "#{$CONFIG[:files_dir]}#{id}"
   File.delete(filename) if File.exist?(filename)

   # file.yml
   Files.instance($CONFIG[:files]).delete(id)
   
   # room.yml
   rooms = Rooms.instance($CONFIG[:rooms])
   room = rooms.find(roomid)
   room["files"].delete(id)
   rooms.flush
   
   # copied...
   redirect "../../#{roomid}"
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
   
   rooms = Rooms.instance($CONFIG[:rooms])
   files = Files.instance($CONFIG[:files])
   rooms.find(roomid)['files'].each do |f|
      filename = "#{$CONFIG[:files_dir]}#{id}"
      File.delete(filename) if File.exist?(filename)
      files.delete(f)
   end
   rooms.delete(roomid)
   redirect '../rooms'
end

get '/:roomid/:fileid' do |roomid, fileid|
   redirect '../login' if !user?(session) and !room?(session, roomid)
   
   file = Files.instance($CONFIG[:files]).find(fileid.to_i)
   if file
      content_type 'application/octet-stream', :charset => 'utf-8'
      attachment "#{$CONFIG[:files_dir]}#{file['name']}"
      send_file "#{$CONFIG[:files_dir]}#{file['id']}"
   else
      "no file id=#{fileid}"
   end
end

get '/:roomid' do |roomid|
   redirect './login' if !user?(session) and !room?(session, roomid)
   room = Rooms.instance($CONFIG[:rooms]).find(roomid)
   files = Files.instance($CONFIG[:files])
   
   files_in_room = []
   room['files'].each do |i|
      files_in_room << files.find(i)
   end
   
   erb :files, :locals => {
      :room => room,
      :files => files_in_room,
      :constants => $CONFIG
   }
end

post '/:roomid' do |roomid|
   redirect './login' if !user?(session) and !room?(session, roomid)
   
   room = Rooms.instance($CONFIG[:rooms]).find(roomid)
   if params[:upfile]
      p params
      
      # fixme: always size = 0
      size = File.stat(params[:upfile][:tempfile].path).size
      p File.stat(params[:upfile][:tempfile].path).ctime
      files = Files.instance($CONFIG[:files])
      file_id = files.add({
         :name => params[:upfile][:filename],
         :type => params[:upfile][:type],
         :note => params[:note],
         :size => size
         })
      
      room['files'] << file_id
      Rooms.instance($CONFIG[:rooms]).flush
      
      # at windows, cannot mv.
      FileUtils.cp(params[:upfile][:tempfile].path, "#{$CONFIG[:files_dir]}#{file_id}")
   end
   
   files = Files.instance($CONFIG[:files])
   
   # code copied
   files_in_room = []
   room['files'].each do |i|
      files_in_room << files.find(i)
   end
   
   erb :files, :locals => {
      :room => room,
      :files => files_in_room,
      :constants => $CONFIG
   }
end

