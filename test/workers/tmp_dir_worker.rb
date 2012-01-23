class TmpDirWorker < IronWorker::Base
  def run
    puts "User dir content=#{Dir.glob("#{user_dir}*")}"
    puts "TMPDIR=#{ENV["TMPDIR"]}" if ENV["TMPDIR"]
  end
end