require 'data_mapper' # metagem, requires common plugins too.

class User
    include DataMapper::Resource
    property :id, Serial
    property :email, String
    property :password, String
    property :created_at, DateTime
    property :administrator, Boolean, :default => false
    property :pro, Boolean, :default => false
    property :name, String
    def login(password)
    	return self.password == password
    end
end
