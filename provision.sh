#!/bin/bash
# Set start time
time_start="$(date +%s)"

# Get domain name passed from Vagrantfile
vagrant_domain=$1


# Swap
echo "Setting up swap..."
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
sysctl vm.swappiness=10
sysctl vm.vfs_cache_pressure=50
sh -c "printf 'vm.swappiness=10\n' >> /etc/sysctl.conf"
sh -c "printf 'vm.vfs_cache_pressure=50\n' >> /etc/sysctl.conf"


# Set MySQL default root password
echo "Setting up root MySQL password..."
echo mariadb-server mysql-server/root_password password password | debconf-set-selections
echo mariadb-server mysql-server/root_password_again password password | debconf-set-selections

# phpMyAdmin unattended installation
echo "Setting up default phpMyAdmin configuration..."
echo phpmyadmin phpmyadmin/dbconfig-install boolean true | debconf-set-selections
echo phpmyadmin phpmyadmin/app-password-confirm password password | debconf-set-selections
echo phpmyadmin phpmyadmin/mysql/admin-pass password password | debconf-set-selections
echo phpmyadmin phpmyadmin/mysql/app-pass password password | debconf-set-selections
echo phpmyadmin phpmyadmin/reconfigure-webserver multiselect none | debconf-set-selections

echo "Updating packages list..."
apt-get update && \
apt-get upgrade -y && \
apt-get install -yqq \
    build-essential \
    git \
    imagemagick \
    mariadb-server\
    nginx \
    nodejs \
    npm \
    ntp \
    php-curl \
    php-fpm \
    php-dev \
    php-gd \
    php-imap \
    php-mbstring \
    php-mysql \
    php-soap \
    php-xml \
    php-xmlrpc \
    php-zip \
    php-imagick \
    php-pear \
    subversion \
    unzip \
    zip

# Install phpmyadmin separately
apt-get install -y phpmyadmin

# Install Composer
if [ ! -f /usr/local/bin/composer ]; then
    echo "Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    chmod +x composer.phar
    mv composer.phar /usr/local/bin/composer
fi

# Install WP-CLI
if [ ! -f /usr/local/bin/wp ]; then
    echo "Installing wp-cli..."
    curl -sS -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi




# Install mailhog
echo "Installing mailhog..."
wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v0.2.1/MailHog_linux_amd64
chmod +x ~/mailhog
mv ~/mailhog /usr/local/bin/mailhog

# Install mhsendmail
echo "Installing mhsendmail..."
wget --quiet -O ~/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64
chmod +x ~/mhsendmail
mv ~/mhsendmail /usr/local/bin/mhsendmail

# Post installation cleanup
echo "Cleaning up..."
apt-get -y autoremove

# nginx initial setup
echo "Configuring nginx..."
cp /srv/config/nginx/nginx.conf /etc/nginx/nginx.conf
cp /srv/config/nginx/default.conf /etc/nginx/conf.d/default.conf
cp /srv/config/nginx/mail.conf /etc/nginx/conf.d/mail.conf
cp /srv/config/nginx/db.conf /etc/nginx/conf.d/db.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/default.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/mail.conf
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/nginx/conf.d/db.conf

# PHP initial setup
echo "Configuring PHP..."
phpenmod mbstring
cp /srv/config/php/php-custom.ini /etc/php/7.4/fpm/conf.d/php-custom.ini
sed -i "s/VAGRANT_DOMAIN/$vagrant_domain/g" /etc/php/7.4/fpm/conf.d/php-custom.ini

# MySQL initial setup
echo "Configuring MySQL..."
mysql_secure_installation<<EOF
password
n
Y
Y
Y
Y
EOF

EXPECTED_ARGS=3
MYSQL=`which mysql`
#Q1="CREATE DATABASE IF NOT EXISTS $DBNAME;"
Q2="GRANT ALL ON *.* TO '$DBUSER'@'localhost' IDENTIFIED BY '$DBPASS';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q2}${Q3}"
$MYSQL -uroot -p$DBROOTPASS -e "$SQL"

# phpMyAdmin initial setup
#echo "Configuring phpMyAdmin..."
cp /srv/config/phpmyadmin/config.inc.php /etc/phpmyadmin/config.inc.php

# Mailhog initial setup
echo "Configuring Mailhog..."
cp /srv/config/mailhog/mailhog.service  /etc/systemd/system/mailhog.service
systemctl enable mailhog

# Restart all the services
echo "Restarting services..."
service mysql restart
service php7.4-fpm restart
service nginx restart
service mailhog start

# Add ubuntu user to the www-data group with correct owner
echo "Adding user to the correct group..."
usermod -a -G www-data ubuntu
mkdir -p /srv/www/html/wordpress
chown -R www-data:www-data /srv/www/


#checkout theme
mkdir /srv/tmp
cd /srv/tmp
git clone https://$GIT_USER:"$GIT_PASS"@$GIT_REPO

#install WP
cd /srv/www/html/wordpress
wp core download --version=$WP_VERSION --allow-root
wp core config --dbprefix=$DBPREFIX --dbname=$DBNAME --dbuser=$DBUSER --dbpass=$DBPASS --allow-root
wp db create --allow-root
wp core install --url="$WPURL" --title="$WPSITENAME" --admin_user="$WPADMUSER" --admin_password="$WPADMPASS" --admin_email="$WPADMEMAIL" --allow-root
sudo -u www-data  wp db import /srv/$DB_DUMP --dbuser=$DBUSER --dbpass=$DBPASS
sudo -u www-data  wp option update home "$WPURL" 
sudo -u www-data  wp option update siteurl "$WPURL" 
sudo -u www-data  wp user update $WPADMUSER --user_pass="$WPADMPASS"

#Install WP Plugins
sudo -u www-data  wp plugin install contact-form-7 \
                                    contact-form-7-dynamic-select-extension \
                                    custom-post-type-ui \
                                    cyr3lat \
                                    easy-testimonials \
                                    really-simple-ssl \
                                    wpglobus \
                                    advanced-custom-fields \
                                    ga-google-analytics\
                                    wonderm00ns-simple-facebook-open-graph-tags --activate

#install theme
cp -r /srv/tmp/onix.kr.ua/wordpress/wp-content/themes/onix-ua /srv/www/html/wordpress/wp-content/themes/onix-ua
cd /srv/www/html/wordpress/wp-content/themes/onix-ua
npm cache verify
npm install --no-bin-links


#Enable theme
sudo -u www-data wp theme activate onix-ua

# Calculate time taken and inform the user
time_end="$(date +%s)"
echo "Provisioning completed in "$(expr $time_end - $time_start)" seconds"
