


require "getoptlong"
require "pp"
require 'fileutils'
require 'rubyhacks'
# require '/home/edmundhighcock/Code/coderunner/trunk/box_of_tricks.rb'
$default_host_manager_store = ENV['HOME'] + '/.host_manager_data.rb'

# $script_folder = File.dirname(File.expand_path(__FILE__)) #i.e. where this script is


class Host
	class_accessor :ssh_option_string
	@@ssh_option_string = ""
	attr_accessor :user_name, :host, :port
	def self.from_string(string)
		return Zeroconf.from_string(string) if string =~ /\(zeroconf\)/
		user_name, host = string.split('@')		  
		return host =~ /\S/ ? new(user_name, host) : Local.new		
	end
	def initialize(user_name, host)
		@host = host; @user_name = user_name.gsub(/ /, '\ '); @port = nil
	end
	def setup #see Zeroconf
	end
	def rsync_scp_remote
		setup
		@user_name ? "#@user_name@#@host:" : "#@host:"
	end
	def rsync_scp_local
		setup
		""
	end
	def ssh
		setup
		@user_name ? "ssh #@@ssh_option_string #@user_name@#@host" : "ssh #@@ssh_option_string #@host"
	end
	def sshfs
		setup
		@user_name ? "sshfs #@@ssh_option_string #@user_name@#@host:" : "sshfs #@@ssh_option_string #@host:"
	end
	def remote?
		setup
		true
	end
	def control_path_string
	end	


	class Local < Host
		class SSHError < StandardError
		end
		def initialize
			@host = @name = nil
		end
		def rsync_scp_remote
			""
		end
		def rsync_scp_local
			""
		end
		def ssh
			""
		end	
		def remote?
			false
		end
	end

	
	class Forwarded < Host
		def self.from_string(string, port)
			user_name, host = string.split('@')
			new(user_name, port)
		end
		def initialize(user_name, port)
			@port = port
			@user_name = user_name.gsub(/ /, '\ ')
			@host = "localhost"
		end
		def rsync_scp_remote
			"--rsh='ssh -p  #{@port}' #{@user_name}@localhost:"
		end
		def rsync_scp_local
			""
		end
		def ssh
			"ssh -p #{@port} #@@ssh_option_string  #{@user_name}@localhost"
		end
		def sshfs
			"sshfs -p #{@port} #@@ssh_option_string  #{@user_name}@localhost:"
		end
		def remote?
			true
		end
	end

	class Zeroconf < Host
		def self.from_string(string)
			return new(string)
		end
		def initialize(string)
			@string = string
		end
		def setup
			return if @user_name and @host
			@user_name, host = @string.split('@')	
			@user_name.gsub!(/ /, '\ ')
			host = host.sub(/\(zeroconf\)/, '')
			raise 'avahi-utils required for zeroconf hosts' unless system 'avahi-resolve --version > /dev/null'
# # 			puts system "avahi-resolve -n #{host} > /dev/null"
			unless `avahi-resolve -n #{host}` =~ /\d\./
			  puts "Must restart avahi-daemon - please enter an adminstrator password"
# 			  puts system 'sudo /usr/sbin/avahi-daemon -c'
			  if system 'sudo /usr/sbin/avahi-daemon -c'
			    puts `sudo /usr/sbin/avahi-daemon -r`
			  else
			    puts `sudo /usr/sbin/avahi-daemon -D`
			  end
			end
			@host = `avahi-resolve -n #{host}`.split(/\s+/)[1]
		end
	end

end

#= Hostmanager
#
#== Summary
#
#A class and command line utility that allows simple management of ssh hosts and remote folders. E.g. logging in to a remote server becomes as easy as 'hm l y'.
#
#== Examples
#
#  hm add m myname@myhost
#  hm x m
#  hm list
#  hm scp m:my_file h:. 
#  hm rsync -o av m:source/path h:dest/path 
#
#== Command Manual
#
#=== Commands
#
#  hm add <letter> myname@myhost.com --- Add a host to be referred to with <letter>
#  hm list -- List all hosts
#  hm l <letter> -- Login to a host with ssh 
#  hm x <letter> -- Login to a host with ssh -X
#  hm scp <letter1>:<file1> <letter2>:<file2> -- Copy file1 from host letter1 to host letter2
#  hm rsync <letter1>:<path1> <letter2>:<path2> -- Sync path1 on host 
#       letter1 to path2 on host letter2 using rsync
#  hm sshfs <letter>:<path> <localpath> -- Mount path on host letter to localpath using sshfs
#
#=== Options
#
#  -z --- host is a zero conf host
#  -o <optionstring> -- Add optionstring to command   
#  -T -- 'test': print out the resulting command without running it

class HostManager
	attr_accessor :host_list, :hosts, :forwards, :content_list, :option_string
	def initialize(hash={})
		hash.each do |key, value|
			self.class.send(:attr_accessor, key)
			set(key, value)
		end
		@host_list ||= {}
		@host_list['h'] = ''
		@host_list['l'] = ENV['USER'] + '@localhost'
		@host_list.each do |letter, string|
			string.sub!(/:$/, '')
		end
		@forwards ||= {}
		@content_list ||= {}
		@hosts = {}
		@start_port ||= 29800
		@host_list.each do |letter, host_string|
			if @forwards[letter]
				@hosts[letter] = Host::Forwarded.from_string(host_string, @forwards[letter])
				unless (string =  "#{@hosts[letter].ssh} cd . 2>/dev/null"; system string)
# 					puts 'port failed'
					@forwards.delete(letter)
					@hosts[letter] = Host.from_string(host_string)
				else
# 					puts 'port passed'
				end
# 				exit
			elsif host_string == nil
				host_string = @host_list[letter] = ""
				redo
			else
				@hosts[letter] = Host.from_string(host_string)
			end
		end
	end
	def add(letter, hosturl)
		raise 'A host label can only be one letter or symbol' unless letter.length == 1
		case letter
		when "h"
			puts "h can only be used to mean 'home', i.e. an empty string"
			return
		when "l"
			puts "l can only be used to mean $USER@localhost"
			return
		else
			(puts 'This host already exists. Do you want to replace it? Press enter to replace it or Ctrl + C to cancel.'; $stdin.gets) if host_list[letter]
			host_list[letter] = hosturl
		end
	end

	def inspect
		@hosts = "Don't edit this variable"
		hash = instance_variables.inject({}) do |hash, var|
			name = var.to_s.sub(/@/, '').to_sym
			hash[name] = instance_variable_get(var)
			hash
		end
		return "HostManager.new(\n#{hash.pretty_inspect.gsub(/\n/, "\n\t")}\n)"
	end
	def login(letter)
		Host.ssh_option_string = @option_string
		return @hosts[letter].ssh
	end
	def both_remote?(*letters)
		return letters.inject(true){|bool, letter| bool and @hosts[letter].remote?}
	end
	def scp(from_letter, from_folder, to_letter, to_folder)
		if both_remote?(from_letter, to_letter)
			return "#{@hosts[to_letter].ssh} scp #@option_string #{@hosts[from_letter].rsync_scp_remote}#{from_folder}  #{@hosts[to_letter].rsync_scp_local}#{to_folder}"
		else
			return "scp #@option_string #{@hosts[from_letter].rsync_scp_remote}#{from_folder}  #{@hosts[to_letter].rsync_scp_remote}#{to_folder}"
		end
	end
	def rsync(from_letter, from_folder, to_letter, to_folder)
		if both_remote?(from_letter, to_letter)
			return "#{@hosts[to_letter].ssh} rsync #@option_string #{@hosts[from_letter].rsync_scp_remote}#{from_folder}  #{@hosts[to_letter].rsync_scp_local}#{to_folder}"
		else
			return "rsync #@option_string #{@hosts[from_letter].rsync_scp_remote}#{from_folder}  #{@hosts[to_letter].rsync_scp_remote}#{to_folder}"
		end
	end
	def port_forward(via_letter, destination_letter)
		raise "Port forwarding already active for #{destination_letter}" if  @forwards[destination_letter]
		@forwards[destination_letter] = @start_port + destination_letter.ord
		%[#{@hosts[via_letter].ssh} -L #{@forwards[destination_letter]}:#{@hosts[destination_letter].host}:22]
	end
	def host(letter)
		return @hosts[letter].host
	end
	def user_name(letter)
		return @hosts[letter].user_name
	end
	def sshfs(letter, remote_folder = nil, local_folder)
		return @hosts[letter].sshfs + "#{remote_folder} #{local_folder}"
	end
	def ssh(letter)
		return @hosts[letter].ssh
	end
	def rsync_scp(letter)
		return @hosts[letter].rsync_scp_remote
	end
end


