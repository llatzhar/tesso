require 'yaml_fix'
require 'nkf'

module YamlStore
   
   include Enumerable
   
   def initialize(filename)
      @filename = filename
      @objects = YAML.load_file(@filename)
   end
   
   def each
      @objects.each do |o|
         yield o
      end
   end
   
   def find(id)
      #p @objects
      @objects.each do |o|
         if o['id'] == id
            return o
         end
      end
      nil
   end
   
   def flush
      File.open(@filename, "w") do |file|
         file.flock(File::LOCK_EX)
         file.write @objects.to_yaml
         file.flock(File::LOCK_UN)
      end
   end
   
   def authenticate(id, pass)
      @objects.each do |o|
         if (id == o["id"]) && (pass == o["pass"])
            return o
         end
      end
      nil
   end
end

class Users
   
   include YamlStore
   
   def initialize(filename)
      super(filename)
      #@users = YAML.load_file('users.yml')
   end
   
   def Users.instance(filename)
      if @instance == nil
         @instance = new(filename)
      end
      @instance
   end
   
   def add(params)
      u = {}
      u['id'] = params['id']
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])
      u['role'] = "user"
      @objects << u
      
      flush
   end
   
   #TODO edit user_id(with check).
   def edit(params)
      u = find(params['id'])
      if u == nil
         return
      end
      
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])
      
      flush
   end
   
   def delete(name)
      @objects.delete(find(name))
      flush
   end
end

class Rooms
   include YamlStore
   
   def initialize(filename)
      super(filename)
   end
   
   def Rooms.instance(filename)
      if @instance == nil
         @instance = new(filename)
      end
      @instance
   end
   
   def add(params)
      # TODO check id
      room = {}
      room['id'] = params['id']
      room['name'] = NKF.nkf('-Ww --cp932', params['name'])
      room['pass'] = params['pass']
      room['note'] = NKF.nkf('-Ww --cp932', params['note'])
      room['files'] = []
      @objects << room
      
      flush
   end
   
   def edit(params)
      u = find(params['id'])
      if u == nil
         return
      end
      
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])

      flush
   end
   
   def delete(name)
      @objects.delete(find(name))
      flush
   end
end

class Files
   include YamlStore
   
   def initialize(filename)
      super(filename)
   end
   
   def Files.instance(filename)
      if @instance == nil
         @instance = new(filename)
      end
      @instance
   end
   
   def next_id
      @objects.last['id'].succ
   end
   
   def add(params)
      file = {}
      id = next_id
      file['id'] = id
      file['name'] = NKF.nkf('-Ww --cp932', params[:name])
      file['type'] = params[:type]
      file['note'] = NKF.nkf('-Ww --cp932', params[:note])
      file['size'] = params[:size]
      file['date'] = Time.now
      @objects << file
      
      flush
      
      id
   end
   
   def edit(params)
      u = find(params['id'])
      if u == nil
         return
      end
      
      u['name'] = NKF.nkf('-Ww --cp932', params['name'])
      u['pass'] = params['pass']
      u['note'] = NKF.nkf('-Ww --cp932', params['note'])

      flush
   end
   
   def delete(id)
      @objects.delete(find(id))
      flush
   end
end
