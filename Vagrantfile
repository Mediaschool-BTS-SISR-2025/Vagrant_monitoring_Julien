Vagrant.configure("2") do |config|
  # VM monitor
  config.vm.define "monitor" do |monitor|
    monitor.vm.box = "debian/bookworm64"
    monitor.vm.hostname = "monitor.mediaschool.local"
    monitor.vm.network "private_network", ip: "192.168.56.10"
    
    # Redirection des ports pour accès local (optionnel)
    monitor.vm.network "forwarded_port", guest: 9090, host: 9090
    monitor.vm.network "forwarded_port", guest: 9100, host: 9100
    monitor.vm.network "forwarded_port", guest: 9093, host: 9093
    monitor.vm.network "forwarded_port", guest: 3000, host: 3000

    # Provisionnement (bash script à écrire)
    monitor.vm.provision "shell", path: "scripts/setup_monitor.sh"
  end

  # VM node1
  config.vm.define "node1" do |node1|
    node1.vm.box = "debian/bookworm64"
    node1.vm.hostname = "node1.mediaschool.local"
    node1.vm.network "private_network", ip: "192.168.56.102"
    
    node1.vm.network "forwarded_port", guest: 9100, host: 9110

    node1.vm.provision "shell", path: "scripts/setup_node1.sh"
  end
end


