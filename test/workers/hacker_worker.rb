# bump......
class HackerWorker < IronWorker::Base

  #merge_gem 'stathat'

  attr_accessor :x

  def run
    puts "hello world! #{x}"
    #puts StatHat::API.class.name
    puts "\n"

    puts 'user_dir: ' + user_dir.to_s
    puts "\n"
    command 'pwd'

    filepath = "#{user_dir}myfile.txt"
    puts "Writing file to #{filepath}..."
    File.open(filepath, 'w') do |fo|
      fo.write "THIS IS MY FILE"
    end

    command 'node --version'
    command 'go version', :includes=>'go version go1'
    command 'java -version', :includes=>'icedtea'
    command 'mono -V', :includes=>'Mono JIT compliler version'
    command 'gmcs hello.cs'


    command 'ls -al'
    command 'cat myfile.txt'
    command 'echo "hello" >> greetings.txt'
    command 'cat myfile.txt'
    command 'ls -al /usr/bin'
    command 'ls -al /mnt'
    command 'ps -ef'
    command 'cat /etc/passwd'
    command 'env'
    puts 'RUBY ENV:'
    puts ENV.inspect
    puts "\n"
    command 'gem environment'
    command 'gem list', :includes=>'typhoeus'
    begin
      command 'sudo ps -ef'
      raise "Should not make it here!"
    rescue => ex
      puts "Expected error running sudo: #{ex.class.name}: #{ex.message}"
    end
    command 'su root'
    command 'ls -al /home/ubuntu'
    command 'ls -al /root'

  end

  def command(s, params={})
    puts "Running #{s}:"
    res = `#{s}`
    if params[:includes]
      raise "Did not include #{params[:includes]}" unless res.include?(params[:includes])
    end
    puts res
    puts "\n"
  end
end
