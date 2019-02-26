require 'sinatra'
require_relative "user.rb"

enable :sessions

get "/login" do
	erb :"authentication/login"
end


post "/process_login" do
	email = params[:email]
	password = params[:password]

	user = User.first(email: email.downcase)

	if(user && user.login(password))
		session[:user_id] = user.id
		redirect "/"
	else
		erb :"authentication/invalid_login"
	end
end

get "/logout" do
	session[:user_id] = nil
	redirect "/"
end

get "/sign_up" do
	erb :"authentication/sign_up"
end


post "/register" do
	email = params[:email]
	password = params[:password]
	name = params[:name]

	if email && password && User.first(email: email.downcase).nil?
		u = User.new
		u.name = name
		u.email = email.downcase
		u.password =  password
		u.save

		session[:user_id] = u.id

		erb :"authentication/successful_signup"
	else
		erb :"authentication/failed_signup"
	end

end

#This method will return the user object of the currently signed in user
#Returns nil if not signed in
def current_user
	if(session[:user_id])
		@u ||= User.first(id: session[:user_id])
		return @u
	else
		return nil
	end
end

#if the user is not signed in, will redirect to login page
def authenticate!
	if !current_user
		redirect "/login"
	end
end

#checks if it is an admin and if it isnt redirects to home page
def admin_only!
	if !current_user.administrator || !current_user
		redirect "/"
	end
end

def free_user!
	authenticate!
	if current_user.administrator || current_user.pro
		redirect "/"
	end
end

