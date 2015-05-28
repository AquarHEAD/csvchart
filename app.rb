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
    File.open("uploads/CL#{params[:changelist]}-#{params[:chartname]}.csv", "w") do |f|
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
  @events = []
  if File.exist? "uploads/#{params[:filename]}"
    pfile = File.new("uploads/#{params[:filename]}")
    plines = pfile.read.lines
    event_idx = plines.index("Time,Events\n")
    if event_idx
      pdata = CSV.parse(plines[5..(event_idx-1)].join)
      event_lines = plines[(event_idx+1)..-1]
      raw_events = event_lines.map do |el|
        {time: el.strip.split(",")[0], description: el.strip.split(",")[1].gsub(/"/, "")}
      end
      raw_events.sort! { |a,b| a[:time] <=> b[:time] }
      @events = raw_events.map do |re|
        "({ xaxis: {from: #{re[:time]}, to: #{re[:time]} }, lineWidth: 0.5, color: '#FFF', description: '#{re[:description]}'})"
      end
    else
      pdata = CSV.parse(plines[5..-1].join)
    end
    pdata.each do |row|
      @frame_data.push [row[0], row[1]]
      @gt_data.push [row[0], row[2]]
      @rt_data.push [row[0], row[3]]
    end
  end
  @filename = File.basename(params[:filename], File.extname(params[:filename]))
  @title = @filename
  haml :chart
end

get "/delete/:filename/?" do
  if File.exist? "uploads/#{params[:filename]}"
    File.delete "uploads/#{params[:filename]}"
  end
  redirect "/"
end

get "/multi/:multifiles/?" do
  @title = "Multi Chart"
  @files = []
  params[:multifiles].split(";").each do |filename|
    frame_data = []
    gt_data = []
    rt_data = []
    events = []
    if File.exist? "uploads/#{filename}"
      pfile = File.new("uploads/#{filename}")
      plines = pfile.read.lines
      event_idx = plines.index("Time,Events\n")
      if event_idx
        pdata = CSV.parse(plines[5..(event_idx-1)].join)
        event_lines = plines[(event_idx+1)..-1]
        raw_events = event_lines.map do |el|
          {time: el.strip.split(",")[0], description: el.strip.split(",")[1].gsub(/"/, "")}
        end
        raw_events.sort! { |a,b| a[:time] <=> b[:time] }
        events = raw_events.map do |re|
          "({ xaxis: {from: #{re[:time]}, to: #{re[:time]} }, lineWidth: 0.5, color: '#FFF', description: '#{re[:description]}'})"
        end
      else
        pdata = CSV.parse(plines[5..-1].join)
      end
      pdata.each do |row|
        frame_data.push [row[0], row[1]]
        gt_data.push [row[0], row[2]]
        rt_data.push [row[0], row[3]]
      end
    end
    basename = File.basename(filename, File.extname(filename))
    @files.push({basename: basename, fd: frame_data, gd: gt_data, rd: rt_data, ed: events})
  end
  haml :multi
end
