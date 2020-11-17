### VAGRANT Environment for WP dev - currently for Linux only
Requirements:
  - Linux host kernel v.5.x
  - Vagrant
  - VBox
  - NFSd installed
  - nfsd, rpc_bind,mountd allowed in firewall for Vagant network
  - vagrant-hostupdater(```vagrant plugin install vagrant-hostsupdater```)

1.  Clone repo
2.  Copy config.yml.sample as config.yml
3.  Set config variables
4.  Run vagrant up
5.  Navigate to SITE_NAME.local in your browser.
6. Additionally, db.SITE_NAME.local = PMA installation, mail.SITE_NAME.local:8025=MailHog