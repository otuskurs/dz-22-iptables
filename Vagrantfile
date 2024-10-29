# -*- mode: ruby -*-
# vim: set ft=ruby :

MACHINES = {
    :inetRouter => {
        :box_name => "ubuntu/jammy64",
        :vm_name => "inetRouter",
        :net => [
            {ip: '192.168.255.1', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
            {ip: '192.168.56.10', adapter: 8},
        ]
    },
    :inetRouter2 => {
        :box_name => "ubuntu/jammy64",
        :vm_name => "inetRouter2",
        :net => [
            {ip: '192.168.255.13', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router2-net"},
            {ip: '192.168.56.13', adapter: 8},
        ]
    },    
    :centralRouter => {
        :box_name => "ubuntu/jammy64",
        :vm_name => "centralRouter",
        :net => [
            {ip: '192.168.255.2', adapter: 2, netmask: "255.255.255.252", virtualbox__intnet: "router-net"},
            {ip: '192.168.0.1', adapter: 3, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
            {ip: '192.168.0.65', adapter: 5, netmask: "255.255.255.192", virtualbox__intnet: "mgt-net"},
            {ip: '192.168.255.14', adapter: 4, netmask: "255.255.255.252", virtualbox__intnet: "router2-net"},
            {ip: '192.168.255.9', adapter: 6, netmask: "255.255.255.252", virtualbox__intnet: "office1-central"},
            {ip: '192.168.255.5', adapter: 7, netmask: "255.255.255.252", virtualbox__intnet: "office2-central"},
            {ip: '192.168.56.11', adapter: 8},
        ]
    },
    :centralServer => {
    :box_name => "ubuntu/jammy64",
    :vm_name => "centralServer",
    :net => [
        {ip: '192.168.0.2', adapter: 2, netmask: "255.255.255.240", virtualbox__intnet: "dir-net"},
        {ip: '192.168.56.12', adapter: 8, netmask: "255.255.255.0"}
    ]
},
}

Vagrant.configure("2") do |config|
    MACHINES.each do |boxname, boxconfig|
        config.vm.define boxname do |box|
            
            box.vm.box = boxconfig[:box_name]
            box.vm.host_name = boxconfig[:vm_name]

            box.vm.provider "virtualbox" do |v|
                v.memory = 1024
                v.cpus = 1
            end

            if boxconfig[:vm_name] == "centralServer"
                box.vm.provision "ansible" do |ansible|
                    ansible.playbook = "ansible/playbook.yml"
                    ansible.inventory_path = "ansible/inventory"
                    ansible.host_key_checking = "false"
                    ansible.limit = "all"
                end
            end

            boxconfig[:net].each do |ipconf|
                box.vm.network "private_network", ip: ipconf[:ip], adapter: ipconf[:adapter], netmask: ipconf[:netmask], virtualbox__intnet: ipconf[:virtualbox__intnet]
            end

            if boxconfig.key?(:public)
                box.vm.network "public_network", boxconfig[:public]
            end

            box.vm.provision "shell", inline: <<-SHELL
                sudo apt-get update
                sudo apt-get install -y python3
                if [ ! -f /usr/bin/python ]; then
                    sudo ln -s /usr/bin/python3 /usr/bin/python
                fi
                mkdir -p ~root/.ssh
                cp ~vagrant/.ssh/auth* ~root/.ssh
            SHELL

            case boxname.to_s
            when "inetRouter2"
                box.vm.network "forwarded_port", guest: 80, host: 8080
            end
        end
    end
end


