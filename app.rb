require "sinatra"
require_relative "authentication.rb"
require 'stripe' #i added

set :publishable_key, "pk_test_vMRHGmEmDhOfOCkV6X33LEkB"
 # i added
set :secret_key, "sk_test_AW7CTIUPkDV1LmaNkw9tPqjM"
 # i added
Stripe.api_key = settings.secret_key
# need install dm-sqlite-adapter
# if on heroku, use Postgres database
# if not use sqlite3 database I gave you
if ENV['DATABASE_URL']
  DataMapper::setup(:default, ENV['DATABASE_URL'] || 'postgres://localhost/mydb')
else
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app.db")
end

class Video
	include DataMapper::Resource
	property :id, Serial
	property :title, Text
	property :description, Text
	property :video_url, Text
	property :pro, Boolean, :default => false

end

DataMapper.finalize
User.auto_upgrade!
Video.auto_upgrade!


#make an admin user if one doesn't exist!
if User.all(administrator: true).count == 0
	u = User.new
	u.email = "admin@admin.com"
	u.password = "admin"
	u.administrator = true
	u.save
end

#the following urls are included in authentication.rb
# GET /login
# GET /logout
# GET /sign_up

# authenticate! will make sure that the user is signed in, if they are not they will be redirected to the login page
# if the user is signed in, current_user will refer to the signed in user object.
# if they are not signed in, current_user will be nil

#EMBEDS YOUTUBE VIDEOS
def youtube_embed(youtube_url)
  if youtube_url[/youtu\.be\/([^\?]*)/]
    youtube_id = $1
  else
    # Regex from # http://stackoverflow.com/questions/3452546/javascript-regex-how-to-get-youtube-video-id-from-url/4811367#4811367
    youtube_url[/^.*((v\/)|(embed\/)|(watch\?))\??v?=?([^\&\?]*).*/]
    youtube_id = $5
  end

  %Q{<iframe title="YouTube video player" width="640" height="390" src="https://www.youtube.com/embed/#{ youtube_id }" frameborder="0" allowfullscreen></iframe>}
end
#####

get "/" do
	erb :index
end

get "/videos" do
  authenticate!
  if current_user.administrator == false && current_user.pro == false
    @videos = Video.all(pro: false)
  else
     @videos = Video.all
  end
     erb :videos
end

post "/videos/create" do
  admin_only!
	if params["title"] && params["description"] && params["video_url"]
		v = Video.new
		v.title = params["title"]
		v.description = params["description"]
		v.video_url = params["video_url"]
    v.pro = true if params["pro"]
		v.save
    redirect "/videos"
	end
end


get "/videos/new" do
  authenticate!
  admin_only!
	erb :new_videos
end

get '/upgrade' do
  free_user!
  erb :upgrade
end                   

post '/charge' do
  # Amount in cents
  @amount = 500

  customer = Stripe::Customer.create(
    :email => 'customer@example.com',
    :source  => params[:stripeToken]
  )

  charge = Stripe::Charge.create(
    :amount      => @amount,
    :description => 'Sinatra Charge',
    :currency    => 'usd',
    :customer    => customer.id
  )

  current_user.pro = true
  current_user.save

  erb :charge
rescue
  redirect "/upgrade"
end
