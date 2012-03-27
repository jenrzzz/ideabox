require 'sinatra'
require 'data_mapper'

DataMapper::Logger.new($stdout, :debug)
DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data.db")

class Idea
    include DataMapper::Resource
    property :id, Serial
    property :title, String
    property :text, Text
    property :created, DateTime
end

DataMapper.finalize.auto_upgrade!

get '/' do
    @ideas = Idea.all :order => [ :id.desc ]
    @title = "List"
    erb :ideas
end

post '/' do
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
    lidea = Idea.get params[:id]
    if lidea == nil
        redirect '/'
    end
    lidea.update(
        :title => params[:title],
        :text => params[:ideatext],
    )
    redirect '/'
end

get '/:id/delete' do
    @idea = Idea.get params[:id]
    @title = "Deleting " + @idea.title
    erb :delete
end

delete '/:id' do
    idea = Idea.get params[:id]
    idea.destroy || "Could not find an idea with that title."
    redirect '/'
end
