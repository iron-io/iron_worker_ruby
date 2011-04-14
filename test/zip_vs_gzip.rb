require 'zip'
require 'zlib'

dir = Dir.new("./")
started_at = Time.now
fname2 = "zipped.zip"
Zip::ZipFile.open(fname2, 'w') do |f|
  dir.each do |fname|
    puts "merging #{fname} into #{fname2}"
    f.add(File.basename(fname), fname)
  end
end
ended_at = Time.now
puts "zip duration=#{(ended_at.to_f - started_at.to_f)}"

# todo: need to tar these first.
started_at = Time.now
fname2 = "gzipped.gzip"
Zlib::GzipWriter.open(fname2) do |gz|
   dir.each do |fname|
    puts "merging #{fname} into #{fname2}"
    gz.write(File.basename(fname), fname)
  end
end
ended_at = Time.now
puts "gzip duration=#{(ended_at.to_f - started_at.to_f)}"