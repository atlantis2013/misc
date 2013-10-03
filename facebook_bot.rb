#!/usr/bin/ruby
require 'mechanize'
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def blue(text); colorize(text, 34); end
begin
    browser = Mechanize.new
    browser.get("https://m.facebook.com")
    form = browser.page.form_with(:method => 'POST')
    #form.email = ''
    #form.pass = ''
    form.email = ARGV[0]
    form.pass = ARGV[1]
    browser.submit(form)
    
    form2 = browser.page.form_with(:method => 'POST')
    form2.status = "#{`fortune`}\r\n --ruby-bot"
    browser.submit(form2)
end
