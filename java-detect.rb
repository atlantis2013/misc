require 'win32/registry'
hostname = ENV["COMPUTERNAME"]
version = '7.0.210'
Win32::Registry::HKEY_LOCAL_MACHINE.open('Software\Microsoft\Windows\CurrentVersion\Uninstall') do |reg|
  reg.each_key do |key1,key2|
    k = reg.open(key1)
    t = k["DisplayName"] rescue "?"
    if t.include? 'Java' and not t.eql? 'Java Auto Updater'
      puts t + " " + k["DisplayVersion"]
      if not k["DisplayVersion"].eql? version
       puts 'You should update or remove this version of java!'
      end
    sleep 10
    end
  end
end