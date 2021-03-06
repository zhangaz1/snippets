# Run me with:
#   watchr -d textarcana.watchr
# Also might need to install watchr and ruby-growl:
#   sudo gem install watchr rev ruby-growl

@growl_clients = %w{
    10.0.1.1
    10.0.1.2
}

def check action, title, message
  guid = %x{echo '#{title}' | sha1sum - | cut -d' ' -f1}.chomp
  if system action
    if system %{ls /tmp/#{guid}}
      puts "\033[32;1m" + title + " RECOVERY\n\t" + message + "\033[0m"
      system %{rm /tmp/#{guid}}
      @growl_clients.each do | host  |
        system %{growl -H #{host} -t 'OK: #{title}' -m '#{message} \n #{%x{hostname}}'}
      end
    end
  else
    puts "\033[31;1m" + title + " FAILURE\n\t" + message + "\033[0m"
    system %{touch /tmp/#{guid}}
    @growl_clients.each do | host  |
      system %{growl -H #{host} -t 'FAIL: #{title}' -m '#{message} on\n #{%x{hostname}}'}
    end
  end
end

# --------------------------------------------------
# Rules
# --------------------------------------------------
watch( '(.*?([^/]+\.js)$)' )  { |m|
  check(%{node #{m[1]}},
        'run ' + m[2],
        'Node crash test')

  check(%{jslint #{m[1]} | grep "No errors found."},
        'lint ' + m[2],
        "JSLint")
}

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------

Signal.trap('INT' ) { abort("\n") } # Ctrl-Ce

