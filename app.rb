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
    redirect "/charts/CL#{params[:changelist]}_#{params[:chartname]}.csv"
  end
end

get "/" do
  @files = Dir.entries("uploads").select { |x| (!x.start_with? '.') && (File.extname(x) == ".csv") }.map do |fn|
    {filename: fn, time: File.ctime("uploads/#{fn}")}
  end
  @title = "Index"
  haml :files
end

get "/delete/:filename/?" do
  if File.exist? "uploads/#{params[:filename]}"
    File.delete "uploads/#{params[:filename]}"
  end
  redirect "/"
end

get "/charts/:multifiles/?" do
  @files = []
  filenames = params[:multifiles].split(";")
  filenames.each do |filename|
    this_file = {
      fd: [], # Frame
      gd: [], # GT
      rd: [], # RT
      gpud: [], # GPU
      actord: [], # Actor
      emitterd: [], # Emitter
      vramd: [], # VRAM
      audiod: [], # Audio
      events: [], # Events
    }

    events = []
    if File.exist? "uploads/#{filename}"
      pfile = File.new("uploads/#{filename}")
      plines = pfile.read.lines
      event_idx = plines.find_index { |x| x.start_with? "Time,Events" }
      if event_idx
        pdata = CSV.parse(plines[5..(event_idx-1)].join)
        edata = CSV.parse(plines[(event_idx+1)..-1].join)
        this_file[:events] = edata.map do |ed|
          "({ xaxis: {from: #{ed[0]}, to: #{ed[0]} }, lineWidth: 0.5, color: '#FFF', description: '#{ed[1]}'})"
        end
      else
        pdata = CSV.parse(plines[5..-1].join)
      end
      pdata.each do |row|
        this_file[:fd].push [row[0], row[1]] if row.length >= 2
        this_file[:gd].push [row[0], row[2]] if row.length >= 3
        this_file[:rd].push [row[0], row[3]] if row.length >= 4
        this_file[:gpud].push [row[0], row[4]] if row.length >= 5
        this_file[:actord].push [row[0], row[5]] if row.length >= 6
        this_file[:emitterd].push [row[0], row[6]] if row.length >= 7
        this_file[:vramd].push [row[0], row[7]] if row.length >= 8
        this_file[:audiod].push [row[0], row[8]] if row.length >= 9
      end
    end
    basename = File.basename(filename, File.extname(filename))
    this_file[:basename] = basename

    table_data = nil
    if File.exist? "uploads/#{basename}.html"
      page = Nokogiri::HTML(open("uploads/#{basename}.html"))
      table = page.css("table")[0]
      table.css("table")[0]['class'] = 'table table-bordered'
      table.css("table")[0]['style'] = 'font-size: 12px;'
      table_data = table.to_s
    end
    this_file[:table] = table_data
    @files.push this_file
  end
  if filenames.length > 1
    @title = "Multi Chart"
  else
    @title = @files[0][:basename]
  end
  haml :charts
end

get '/download/:filename/?' do
  send_file "./uploads/#{params[:filename]}", filename: params[:filename], type: "application/octet-stream"
end
