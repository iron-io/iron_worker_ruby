class GemParser
  attr_reader :files

  def initialize
    @files = []
    @parsed = []
  end

  def start(full_gem_name)
    gem_name =(full_gem_name.match(/^[a-zA-Z0-9\-_]+/)[0])
    match = full_gem_name.match(/\/[a-zA-Z0-9\-_\/]+$/)
    additional_gem_path = match ? match[0] : ""
    puts "Searching #{gem_name}"
    #puts "Searching additional_gem_path - #{additional_gem_path}"
    searcher = Gem::GemPathSearcher.new
    gem = searcher.find(gem_name)
    if gem
      @basename = gem.full_gem_path + "/lib/"
      root_file = @basename+ gem_name+ additional_gem_path +".rb"
      @files<<root_file
      extract_filenames(root_file)
    end
    @files
  end

  def extract_filenames(filename)
    #puts "Parsing #{filename}"
    return if @parsed.include?(filename)
    @parsed << filename
    content = open(filename).read
    lines   = []
    content.gsub!(/,\s*(\n|\n\r)/, ", ")
    content.gsub!(/require\s*\(\s*(\n|\n\r)/, "require ")
    #content.gsub!(/require\s*\(/, "require ")
    content.gsub! /^[ \t]*?[ \t]*require(\s|_)(.+)$/ do |line|
      #line.gsub!(/\)\s*$/, "")
      line.gsub!(/__FILE__/, "'"+ filename+"'")
      lines << line.strip
    end
    lines.map! { |line| line.gsub(/(^\s+|\s+$)/, "") }
    lines.each do |line|
      begin
        #puts "evaling:#{line}"
        eval line
      rescue SyntaxError => ex
        puts "exception in eval #{ex.inspect}"
      end
    end
  end

  def require(file)
    filename =@basename+ file+ ".rb"
    #puts filename
    return if !File.exist?(filename) || @files.include?(filename)
    extract_filenames(filename)
    @files << (filename)
  end
  #todo this is just a mock
  def require_relative(file)
    filename =@basename+ file+ ".rb"
    #puts filename
    return if !File.exist?(filename) || @files.include?(filename)
    extract_filenames(filename)
    @files << (filename)
  end
end