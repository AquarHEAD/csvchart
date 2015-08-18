require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'haml'
require 'csv'
require 'nokogiri'

get "/upload/?" do
  @title = "Upload"
  haml :upload
end

post "/upload/?" do
  @errors = []
  unless params[:changelist] && params[:changelist].length > 0
    @errors.push "Must provide a CL number"
  end
  if params[:changelist] && !(/\A\d+\z/ === params[:changelist])
    @errors.push "CL number can only be an integer"
  end
  unless params[:chartname] && params[:chartname].length > 0
    @errors.push "Must provide a meaningful chart name"
  end
  if !params[:csvfile]
    @errors.push "Must provide a CSV file"
  elsif File.extname(params[:csvfile][:filename]) != ".csv"
    @errors.push "Must provide a CSV file"
  end
  if File.exist? "uploads/#{params[:changelist]}_#{params[:platform]}_#{params[:androidversion]}_#{params[:chartname]}.csv"
    @errors.push "Duplicate chart"
  end
  if !params[:htmlfile]
    @errors.push "Must provide a HTML file"
  elsif File.extname(params[:htmlfile][:filename]) != ".html"
    @errors.push "Must provide a HTML file"
  end
  if @errors.length > 0
    @title = "Upload"
    haml :upload
  else
    File.open("uploads/CL#{params[:changelist]}_#{params[:chartname]}.csv", "w") do |f|
      content = params[:csvfile][:tempfile].read
      f.write(content)
    end
    File.open("uploads/CL#{params[:changelist]}_#{params[:chartname]}.html", "w") do |f|
      content = params[:htmlfile][:tempfile].read
      f.write(content)
    end
    redirect "/chart/CL#{params[:changelist]}_#{params[:chartname]}.csv"
  end
end

get "/" do
  @files = Dir.entries("uploads").select { |x| (!x.start_with? '.') && (File.extname(x) == ".csv") }.map do |fn|
    {filename: fn, time: File.ctime("uploads/#{fn}")}
  end
  @title = "Index"
  haml :files
end

get "/chart/:filename/?" do
  @frame_data = []
  @gt_data = []
  @rt_data = []
  if File.exist? "uploads/#{params[:filename]}"
    pfile = File.new("uploads/#{params[:filename]}")
    plines = pfile.read.lines
    event_idx = plines.find_index { |x| x.start_with? "Time,Events" }
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
  @table_data = nil
  if File.exist? "uploads/#{@filename}.html"
    page = Nokogiri::HTML(open("uploads/#{@filename}.html"))
    table = page.css("table")[0]
    table.css("table")[0]['class'] = 'table table-bordered'
    table.css("table")[0]['style'] = 'font-size: 12px;'
    @table_data = table.to_s
  end
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
    temp_data = []
    power_data = []
    events = []
    if File.exist? "uploads/#{filename}"
      pfile = File.new("uploads/#{filename}")
      plines = pfile.read.lines
      event_idx = plines.find_index { |x| x.start_with? "Time,Events" }
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
      if pdata[0].length == 5
        pdata.each do |row|
          frame_data.push [row[0], row[1]]
          gt_data.push [row[0], row[2]]
          rt_data.push [row[0], row[3]]
        end
      elsif pdata[0].length == 7
        pdata.each do |row|
          frame_data.push [row[0], row[1]]
          gt_data.push [row[0], row[2]]
          rt_data.push [row[0], row[3]]
          temp_data.push [row[0], row[5]]
          power_data.push [row[0], row[6]]
        end
      end
    end
    basename = File.basename(filename, File.extname(filename))

    table_data = nil
    if File.exist? "uploads/#{basename}.html"
      page = Nokogiri::HTML(open("uploads/#{basename}.html"))
      table = page.css("table")[0]
      table.css("table")[0]['class'] = 'table table-bordered'
      table.css("table")[0]['style'] = 'font-size: 12px;'
      table_data = table.to_s
    end
    @files.push({basename: basename, fd: frame_data, gd: gt_data, rd: rt_data, td: temp_data, pd: power_data, ed: events, table: table_data})
  end
  haml :multi
end

get '/download/:filename/?' do
  send_file "./uploads/#{params[:filename]}", filename: params[:filename], type: "application/octet-stream"
end
