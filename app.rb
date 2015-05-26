require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'haml'
require 'csv'

get "/upload/?" do
  @title = "Upload"
  haml :upload
end

post "/upload/?" do
  @errors = []
  unless params[:changelist] && params[:changelist].length > 0
    @errors.push "Must provide a CL number"
  end
  unless params[:chartname] && params[:chartname].length > 0
    @errors.push "Must provide a meaningful chart name"
  end
  if !params[:csvfile]
    @errors.push "Must provide a CSV file"
  elsif File.extname(params[:csvfile][:filename]) != ".csv"
    @errors.push "Must provide a CSV file"
  end
  if File.exist? "uploads/#{params[:changelist]}-#{params[:chartname]}.csv"
    @errors.push "Duplicate changelist and chart name"
  end
  if @errors.length > 0
    @title = "Upload"
    haml :upload
  else
    File.open("uploads/#{params[:changelist]}-#{params[:chartname]}.csv", "w") do |f|
      content = params[:csvfile][:tempfile].read
      f.write(content)
    end
    redirect "/chart/#{params[:changelist]}-#{params[:chartname]}.csv"
  end
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

get "/remove/:filename/?" do
  if File.exist? "uploads/#{params[:filename]}"
    File.delete "uploads/#{params[:filename]}"
  end
  redirect "/"
end
