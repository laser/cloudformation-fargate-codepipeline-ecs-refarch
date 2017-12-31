
#!/usr/local/bin/ruby -w

require "pg"
require "uri"

if ENV['DATABASE_URL']
  url = URI.parse(ENV['DATABASE_URL'])
  puts "Waiting for database with URL=#{url}..."
  30.times do
    begin
      PG.connect(url.hostname, url.port, nil, nil, url.path[1..-1], url.user, url.password)
      puts "Success!"
      exit 0
    rescue => e
      print "."
    end
    sleep 1
  end

  exit 1
else
  STDERR.puts "ENV['DATABASE_URL'] is not set; skipping"
end

