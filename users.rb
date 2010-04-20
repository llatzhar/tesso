require 'yaml_fix'
require 'nkf'

class Users
   
   include Enumerable
   
   def initialize
      @users = YAML.load_file('users.yml')
   end
   
   def each
      @users.each do |u|
         yield u
      end
   end
   
   def authenticate(user, pass)
      @users.each do |u|
         if user == u["user_id"] && pass == u["pass"]
            return u
         end
      end
      return nil
   end

   def find_by(uid)
      @users.each do |u|
         if u["user_id"] == uid
            return u
         end
      end
      return nil
   end
   
   def admin?(uid)
      u = find_by(uid)
      u["role"] == "admin"
   end
   
   def user?
      u = find_by(uid)
      u["role"] == "user"
   end
   
   def room?
      raise "not implemented"
   end
   
   def lock
      f = File.open('users.yml', 'r')
      f.flock(File::LOCK_SH)
      # unlockはプロセス死亡時の自動開放に任せる...でいいの？
   end
   
   def flush
      File.open('users.yml', "w") do |file|
         file.flock(File::LOCK_EX)
         file.write @users.to_yaml
         file.flock(File::LOCK_UN)
      end
   end
   
   def add(params)
      u = {}
      u['user_id'] = params['id']
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])
      u['role'] = :user
      u['files'] = []
      @users << u
      
      flush
   end
   
   #TODO edit user_id(with check).
   def edit(params)
      u = find_by(params['id'])
      if u == nil
         return
      end
      
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])

      flush
   end
   
   def delete(name)
      @users.delete(find_by(name))
      
      flush
   end
end
