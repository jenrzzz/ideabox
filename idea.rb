require 'sinatra'
require 'data_mapper'
require 'rdiscount'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data.db")

configure do
  enable :static, :sessions
end

helpers do
    def protected!
        unless authorized?
          response['WWW-Authenticate'] = %(Basic realm="ideabox v0.3")
          throw :halt, [401, "Not authorized\n"]
        end
    end

    def authorized?
        authorized = YAML::load(IO.read(File.join(File.dirname(__FILE__), 'auth.yml')))
        @auth ||= Rack::Auth::Basic::Request.new(request.env)
        valid = @auth.provided? && @auth.basic? && @auth.credentials && authorized.include?(@auth.credentials[0])
        valid && authorized[@auth.credentials[0]] == @auth.credentials[1]
    end
end

class Idea
    include DataMapper::Resource
    property :id, Serial
    property :title, String, :length => 255
    property :text, Text
    property :complete, Boolean
    property :completion_time, DateTime
    property :created, DateTime
    property :karma, Integer, :default => 1
end

DataMapper.finalize.auto_upgrade!

get '/' do
    protected!
    @ideas = Idea.all :order => [ :karma.desc, :id.desc ]
    @title = "List"
    erb :ideas
end

post '/' do
    protected!
    @idea = Idea.create(
        :title => params[:title],
        :text => params[:ideatext],
        :created => Time.now
    )

    redirect '/'
end

get '/:id' do
    lidea = Idea.get params[:id]
    if lidea == nil
        redirect '/'
    end
    @idea = lidea
    @title = "Idea: " + lidea.title
    erb :permalink
end

post '/:id' do
    protected!
    idea = Idea.get params[:id]
    return "Idea ##{params[:id]} not found." if not idea
    idea.update(
        :title => params[:title],
        :text => params[:ideatext],
    )
    redirect '/'
end

get '/:id/upvote' do
    protected!
    idea = Idea.get params[:id]
    redirect '/' if not idea
    idea.karma += 1
    idea.save!
    redirect back
end

get '/:id/downvote' do
    protected!
    idea = Idea.get params[:id]
    redirect '/' if not idea
    idea.karma -= 1
    idea.save!
    redirect back
end

get '/:id/complete' do
    protected!
    idea = Idea.get params[:id]
    redirect '/' if not idea
    idea.complete = true
    idea.completion_time = Time.now
    idea.save!
    redirect back
end

get '/:id/uncomplete' do
    protected!
    idea = Idea.get params[:id]
    redirect '/' if not idea
    idea.complete = false
    idea.completion_time = nil
    idea.save!
    redirect back
end

get '/:id/delete' do
    protected!
    @idea = Idea.get params[:id]
    @title = "Deleting " + @idea.title
    erb :delete
end

delete '/:id' do
    protected!
    idea = Idea.get params[:id]
    idea.destroy || "Could not find an idea with that title."
    redirect '/'
end
