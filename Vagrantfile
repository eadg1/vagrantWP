require 'yaml'

config_file = YAML.load_file("config.yml")
settings = config_file['env'];

Vagrant.configure(2) do |config|

  # vagrant_domain = "onix.kr.ua.local"
  vagrant_ip = settings['vagrant_network'] + rand(256).to_s
  vagrant_sitename=settings['WPSITENAME']
  config.vm.box = "ubuntu/focal64"

  config.vm.network "private_network", ip: "#{vagrant_ip}"
  config.vm.hostname = settings['vagrant_domain']
  config.hostsupdater.aliases = ["mail.#{settings['vagrant_domain']}", "db.#{settings['vagrant_domain']}"]

  config.vm.synced_folder settings['SITE_FOLDER'], "/srv/www/",  type: "nfs", mount_options:["soft", "nolock"]
  config.vm.synced_folder settings['LOGS_FOLDER'], "/srv/log/", type: "nfs", mount_options:["soft", "nolock"]
  config.vm.synced_folder "config/", "/srv/config", type: "nfs", mount_options:["soft", "nolock"]

  config.vm.provider "virtualbox" do |vb|
    vb.gui  = false
    vb.name = vagrant_sitename
    vb.customize ["modifyvm", :id, "--memory", 512]
    vb.customize ["modifyvm", :id, "--cpus", 1]
    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
  end
  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision "shell", path: "provision.sh", env: { 
                                                            DBROOTPASS:settings['DBROOTPASS'], 
                                                            DBPREFIX:settings['DBPREFIX'],
                                                            DBNAME:settings['DBNAME'],
                                                            DBUSER:settings['DBUSER'],
                                                            DBPASS:settings['DBPASS'],
                                                            WPURL:settings['WPURL'],
                                                            WPHOST:settings['WPHOST'],
                                                            WPSITENAME:settings['WPSITENAME'],
                                                            WPADMUSER:settings['WPADMUSER'],
                                                            WPADMPASS:settings['WPADMPASS'],
                                                            WPADMEMAIL:settings['WPADMEMAIL'],
                                                            WP_VERSION:settings['WP_VERSION'],
                                                            GIT_REPO:settings['GIT_REPO'],
                                                            GIT_PASS:settings['GIT_PASS'],
                                                            GIT_USER:settings['GIT_USER'],
                                                            DB_DUMP: settings ['DB_DUMP']
                                                          },
                                                        args: "#{settings['vagrant_domain']}"
end
