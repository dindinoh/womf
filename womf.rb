require 'aws/s3'
require 'sinatra'
use Rack::Logger

# constants
Mykey = 'yours3key'
Myid = 'yours3id'
Myhost = 'yours3.host.com'
Mybucketname = 'yourbucketname'
Myusername = 'thispagesusername'
Mypwd = 'thispagepasswd'

# activate logger
helpers do
  def logger
    request.logger
  end
end

# connect to dreamhost
def connect
    AWS::S3::Base.establish_connection!(
                                        :server            => Myhost,
                                        :use_ssl           => true,
                                        :access_key_id     => Myid,
                                        :secret_access_key => Mykey
                                        )
end

# password protect all
use Rack::Auth::Basic, "my place" do |username, password|
    username == Myusername and password == Mypwd
end

# 404
not_found do
    'this thing you are talking about is nowhere to be found.'
end

# list orgmode bucket files
def filelist
    connect
    orgfiles = "<table>"
    orgmodebucket = AWS::S3::Bucket.find(Mybucketname)
    orgmodebucket.each do |object|
        if !object.key.include?("DS")
            orgfiles << "<tr><td><a href=\"/openfile/#{object.key}\">#{object.key}</a></td><td>#{object.about['content-length']}</td><td>#{object.about['last-modified']}</td></tr>"
        end
    end
    orgfiles << "</table>"
    orgfiles << "<br><br><form action=\"/neworg/\" method=\"post\"><input type='text' name='filename'><input type='submit' value='new'></form>"
    return orgfiles
end

# route / gets file listing
get '/' do
    "<h4>org files</h4>"
    filelist
end

# new file form
post '/neworg/' do
    "<form action=\"/post/#{params[:filename]}\" method=\"post\"><textarea name=\"orgtext\" rows=50 cols=160>\#+TITLE:</textarea><input type='submit' value='Submit'></form>"
end

# edit file
get '/openfile/:filename' do
    connect
    tempstr = ""
    AWS::S3::S3Object.stream(params[:filename], Mybucketname) do |chunk|
    tempstr << chunk
    end
    "<form action=\"/post/#{params[:filename]}\" method=\"post\"><textarea name=\"orgtext\" rows=50 cols=160>#{tempstr}</textarea><input type='submit' value='Submit'></form>"
end

# post file to s3
post '/post/:filename' do
    connect
    AWS::S3::S3Object.store(
                            params[:filename],
                            "#{params[:orgtext]}",
                            Mybucketname,
                            :content_type => 'text/plain'
                            )
    redirect "/" 
end
