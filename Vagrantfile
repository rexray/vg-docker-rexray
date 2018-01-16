# Created by Jonas Rosland, @virtualswede & Matt Cowger, @mcowger
# Many thanks to this post by James Carr: http://blog.james-carr.org/2013/03/17/dynamic-vagrant-nodes/

# vagrant box
vagrantbox="centos_7.3"

# vagrant box url
vagrantboxurl="https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.3/vagrant-centos-7.3.box"

# scaleio admin password
password="Scaleio123"
# add your domain here
domain = 'scaleio.local'

# add your nodes here
nodes = ['master', 'node01','node02']

# add your IPs here
network = "192.168.50"

clusterip = "#{network}.10"
firstmdmip = "#{network}.11"
secondmdmip = "#{network}.12"
tbip = "#{network}.13"

# Install ScaleIO cluster automatically or IM only
#If True a fully working ScaleIO cluster is installed. False mean only IM is installed on node MDM1.
if ENV['VG_SCALEIO_INSTALL']
  scaleioinstall = ENV['VG_SCALEIO_INSTALL'].to_s.downcase
else
  scaleioinstall = "true"
end

# Install Docker automatically
if ENV['VG_DOCKER_INSTALL']
  dockerinstall = ENV['VG_DOCKER_INSTALL'].to_s.downcase
else
  dockerinstall = "true"
end

#Evaluate is ScaleIO is going to be needed
if scaleioinstall == "true"
  #Install The ScaleIO Gateway the traditional way or using a container
  if ENV['VG_SCALEIO_GW_DOCKER']
    scaleiogwdocker = ENV['VG_SCALEIO_GW_DOCKER'].to_s.downcase
  else
    if scaleioinstall == "true" && dockerinstall == "false"
      scaleiogwdocker = "false"
    else
      scaleiogwdocker = "true"
    end
  end
else
  scaleiogwdocker = "none"
end

# Install REX-Ray automatically
if ENV['VG_REXRAY_INSTALL']
  rexrayinstall = ENV['VG_REXRAY_INSTALL'].to_s.downcase
else
  rexrayinstall = "true"
end

# Install and Configure Docker Swarm Automatically
if ENV['VG_SWARM_INSTALL']
  swarminstall = ENV['VG_SWARM_INSTALL'].to_s.downcase
else
  swarminstall = "false"
end

# In some cases more memory is needed for applications.
# this environment variable is used to set the mount of RAM for MDM2 and TB. MDM1 always gets 3GB.
# must be set in 1024 amounts
if ENV['VG_SCALEIO_RAM']
  vmram = ENV['VG_SCALEIO_RAM'].to_s.downcase
else
  vmram = "1024"
end

# Verify that the ScaleIO package has the correct size
if ENV['VG_SCALEIO_VERIFY_FILES']
  verifyfiles = ENV['SCALEIO_VERIFY_FILES'].to_s.downcase
else
  verifyfiles = "true"
end

#Volume Directory needed for VirtualBox volumes when ScaleIO isn't used.
# Create a static place or it will use the locally working path
if ENV['VG_VOLUME_DIR']
  volumedir = ENV['VG_VOLUME_DIR'].to_s.downcase
else
  volumedir = "#{ENV['PWD']}/Volumes"
end

# version of installation package
version = "2.0-0.0"

#OS Version of package
os="el7"

#ZIP OS Version of package
zip_os="OEL7"

# installation folder
siinstall = "/opt/scaleio/siinstall"

# packages folder
packages = "/opt/scaleio/siinstall/ECS/packages"
# package name, was ecs for 1.21, is now EMC-ScaleIO from 1.30
packagename = "EMC-ScaleIO"

# fake device
device = "/home/vagrant/scaleio1"

# loop through the nodes and set hostname
scaleio_nodes = []
subnet=10
nodes.each { |node_name|
  (1..1).each {|n|
    subnet += 1
    scaleio_nodes << {:hostname => "#{node_name}"}
  }
}

Vagrant.configure("2") do |config|
  #config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

  scaleio_nodes.each do |node|
    config.vm.define node[:hostname] do |node_config|
      node_config.vm.box = "#{vagrantbox}"
      node_config.vm.box_url = "#{vagrantboxurl}"
      node_config.vm.host_name = "#{node[:hostname]}.#{domain}"
      node_config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", vmram]
        vb.customize ["storagectl", :id, "--name", "SATA Controller", "--portcount", 30, "--hostiocache", "on"]
        vb.customize ["modifyvm", :id, "--macaddress1", "auto"]
      end

      if node[:hostname] == "master"
        node_config.vm.provider :virtualbox do |vb|
          vb.customize ["modifyvm", :id, "--memory", "3072"]
        end

        node_config.vm.network "private_network", ip: "#{firstmdmip}"

        node_config.vm.provision "shell" do |s|
          s.path = "scripts/master.sh"
          s.args = "-o #{os} -zo #{zip_os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -tb #{tbip} -i #{siinstall} -p #{password} -si #{scaleioinstall} -gw #{scaleiogwdocker} -dk #{dockerinstall} -r #{rexrayinstall} -dir #{volumedir} -ds #{swarminstall}"
        end
      end

      if node[:hostname] == "node01"
        node_config.vm.network "private_network", ip: "#{secondmdmip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/node01.sh"
          s.args = "-o #{os} -zo #{zip_os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -tb #{tbip} -i #{siinstall} -si #{scaleioinstall} -dk #{dockerinstall} -r #{rexrayinstall} -dir #{volumedir} -ds #{swarminstall}"
        end
      end

      if node[:hostname] == "node02"
        node_config.vm.network "private_network", ip: "#{tbip}"
        node_config.vm.provision "shell" do |s|
          s.path = "scripts/node02.sh"
          s.args = "-o #{os} -zo #{zip_os} -v #{version} -n #{packagename} -d #{device} -f #{firstmdmip} -s #{secondmdmip} -tb #{tbip} -i #{siinstall} -p #{password} -si #{scaleioinstall} -dk #{dockerinstall} -r #{rexrayinstall} -dir #{volumedir} -ds #{swarminstall} -vf #{verifyfiles}"
        end
      end

    end
  end
end
