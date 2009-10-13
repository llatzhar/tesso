require 'yaml_fix'

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

   def find_by(name)
      @users.each do |u|
         if u["user_id"] == name
            return u
         end
      end
      return nil
   end
   
   def lock
      f = File.open('users.yml', 'r')
      f.flock(File::LOCK_SH)
      # unlock�̓v���Z�X���S���̎����J���ɔC����B(mod_ruby�ɂ����Ă����ꍇ�ɒ���)
   end
   
   def flush
      File.open('users.yml', "w") do |file|
         file.flock(File::LOCK_EX)
         file.write @users.to_yaml
         file.flock(File::LOCK_UN)
      end
   end
end
