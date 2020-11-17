### VAGRANT Environment for WPdev
Requirements for Linux:
  - Linux host kernel v.5.x
  - Vagrant
  - VirtualBox
  - NFSd installed
  - nfsd, rpc_bind,mountd allowed in firewall for Vagant network
  - vagrant-hostupdater(```vagrant plugin install vagrant-hostsupdater```)
  
Requirements for Windows:

  - Windows 10 
  - Vagrant
  - VirtualBox
  - vagrant plugins installed: vagrant-vbguest, vagrant-hostupdater, vagrant-winnfsd
  - admin-run shell (e.g. cmd -> Run As Administrator, or Posh, or FarManager)
1.  Clone repo
2.  Get sql dump of live db
3.  Copy config.yml.sample as config.yml
4.  Set config variables
5.  Run vagrant up
6.  Navigate to SITE_NAME.local in your browser.
7.  Additionally, db.SITE_NAME.local = PMA installation, mail.SITE_NAME.local:8025=MailHog