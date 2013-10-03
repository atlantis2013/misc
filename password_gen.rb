#!/usr/bin/env ruby
def print_error(text)
  print "\e[31m[-]\e[0m #{text}"
end
begin
  unless ARGV.length == 1
    print_error("#{$0} <password_length>\n")
    exit
  end
  10.times {
    pass = ARGV[0].to_i.times.map {[*'a'..'z',*'A'..'Z',*'0'..'9',*'!'..')'].sample}.join
    print "#{pass}\n"
  }
end
