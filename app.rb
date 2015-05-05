require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'haml'
require 'csv'

get "/upload/?" do
  haml :upload
end

post "/upload/?" do
  if File.extname(params['csvfile'][:filename]) != ".csv"
    halt 401
  end
  File.open('uploads/' + params['csvfile'][:filename], "w") do |f|
    content = params['csvfile'][:tempfile].read
    f.write(content)
  end
  redirect "/chart/#{params['csvfile'][:filename]}"
end

get "/" do
  @files = Dir.entries("uploads").select { |x| !x.start_with? '.' }
  @title = "Index"
  haml :files
end

get "/chart/:filename/?" do
  @frame_data = []
  @gt_data = []
  @rt_data = []
  if File.exist? "uploads/#{params[:filename]}"
    pdata = CSV.read("uploads/#{params[:filename]}")
    pdata[5..-1].each do |row|
      @frame_data.push [row[0], row[1]]
      @gt_data.push [row[0], row[2]]
      @rt_data.push [row[0], row[3]]
    end
  end
  @filename = File.basename(params[:filename], File.extname(params[:filename]))
  @title = @filename
  haml :chart
end
