#!/bin/bash

# Define log file paths
LOG_FOLDER="$HOME/logfolder"
TASK1_LOG="$LOG_FOLDER/task1.log"
TASK2_LOG="$LOG_FOLDER/task2.log"
TASK3_LOG="$LOG_FOLDER/task3.log"

# Create log folder if it doesn't exist
mkdir -p "$LOG_FOLDER"

# Function to output progress messages to a log file
log_progress() {
    local message="$1"
    local logfile="$2"
    local check_status="$3"

    # Log progress message to file
    echo "$(date): $message" >> "$logfile"

    
    # Log command output (both stdout and stderr) to the file
    echo "$output" >> "$logfile"

    # Check the exit status if requested
    if [ "$check_status" = "true" ]; then
        if [ $? -eq 0 ]; then
            # Command succeeded, echo a success message
            echo "Command \"$message\" executed successfully" >> "$logfile"
        else
            # Command failed, echo an error message
            echo "Error: Command \"$message\" failed" >> "$logfile"
        fi
    fi

    # For easy read to check final evaluation message
    echo "--------------------------------------------------------" >> "$logfile"
    echo "--------------------------------------------------------" >> "$logfile"


}

# Function to execute Task 1 - Install PHP, MYSQL, APACHE2, GIT ENABLE APACHE
task_1() {
    log_progress "Task 1 executing..." "$TASK1_LOG" "false"
    log_progress "DESCRITION: Install Apache2, MySql, Php, Git and enable Apache" "$TASK1_LOG" "false"

    log_progress "Updating package lists..." "$TASK1_LOG" "true"
    sudo apt-get update
    log_progress "Installing apache2, mysql-server, php, libapache2-mod-php, php-mysql, and git..." "$TASK1_LOG" "true"
    sudo apt-get install -y apache2 mysql-server php libapache2-mod-php php-mysql git

    log_progress "Adding PHP repository..." "$TASK1_LOG" "true"
    yes | sudo add-apt-repository ppa:ondrej/php

    log_progress "Updating package lists after adding PHP repository..." "$TASK1_LOG" "true"
    sudo apt-get update

    log_progress "Installing additional PHP packages..." "$TASK1_LOG" "true"
    sudo apt-get install php8.3 php8.3-curl php8.3-dom php8.3-mbstring php8.3-xml php8.3-mysql php8.3-sqlite3 zip unzip -y

    log_progress "Purging old PHP version..." "$TASK1_LOG" "true"
    sudo apt-get purge php7.4 php7.4-common -y

    log_progress "Enabling Apache modules..." "$TASK1_LOG" "true"
    sudo a2enmod rewrite
    sudo a2enmod php8.3

    log_progress "Restarting Apache service..." "$TASK1_LOG" "true"
    sudo service apache2 restart

    log_progress "Task 1 completed." "$TASK1_LOG" "true"
}

# Function to execute Task 2
task_2() {
    log_progress "Task 2 executing..." "$TASK2_LOG" "true"
    log_progress "DESCRITION: Configure Mysql, create db, clone git, install composer and edit .env" "$TASK2_LOG" "false"

    log_progress "Task 2 executing..." "$TASK2_LOG" "true"
    MYSQL_COMMANDS=$(cat <<EOF
    CREATE USER 'victor'@'localhost' IDENTIFIED BY '08108722';
    GRANT ALL PRIVILEGES ON laraveldb . * TO 'victor'@'localhost';
    CREATE DATABASE laraveldb;
    SHOW DATABASES;
    FLUSH PRIVILEGES;
EOF
)
    echo "$MYSQL_COMMANDS" | sudo mysql -u root

    cd /usr/bin
    log_progress "Installing composer" "$TASK2_LOG" "true"
    curl -sS https://getcomposer.org/installer | sudo php
    sudo mv composer.phar composer
    composer

    cd /var/www/
    log_progress "Cloning Laravel git repo and install composer in cloned dir ..." "$TASK2_LOG" "true"
    sudo git clone https://github.com/laravel/laravel.git
    cd laravel
    composer install --optimize-autoloader --no-dev
    yes | sudo composer update
    sudo cp .env.example .env

    DB_HOST="localhost"
    DB_DATABASE="laraveldb"
    DB_USERNAME="victor"
    DB_PASSWORD="08108722"
    # Set the path to .env file
    ENV_FILE="/var/www/laravel/.env"
    # Alter the .env file
    log_progress "Altering .env file" "$TASK2_LOG" "true"
    sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST}/" ${ENV_FILE}
    sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" ${ENV_FILE}
    sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" ${ENV_FILE}
    sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" ${ENV_FILE}

    log_progress "Task 2 completed." "$TASK2_LOG" "true"
}

# Function to execute Task 3
task_3() {
    log_progress "Task 3 executing..." "$TASK3_LOG" "true"
    log_progress "DESCRITION: artisan key, apache2 config, " "$TASK3_LOG" "false"

    log_progress "php artisan key:generate" "$TASK3_LOG" "true"
    sudo php artisan key:generate

    log_progress "ps aux | grep 'apache' | awk '{print \$1}' | grep -v root | head -n 1" "$TASK3_LOG" "true"
    sudo ps aux | grep 'apache' | awk '{print $1}' | grep -v root | head -n 1
    log_progress "sudo chown -R www-data storage" "$TASK3_LOG" "true"
    sudo chown -R www-data storage

    log_progress "sudo chown -R www-data bootstrap/cache" "$TASK3_LOG" "true"
    sudo chown -R www-data bootstrap/cache

    cd /etc/apache2/sites-available/
    log_progress "sudo touch laravel.conf" "$TASK3_LOG" "true"
    sudo touch laravel.conf

    log_progress "sudo chown $USER:$USER laravel.conf" "$TASK3_LOG" "true"
    sudo chown $USER:$USER laravel.conf

    log_progress "chmod +w laravel.conf" "$TASK3_LOG" "true"
    sudo chmod +w laravel.conf
    sudo cat<<EOF >laravel.conf
    <VirtualHost *:80>
    ServerName victor@localhost
    DocumentRoot /var/www/laravel/public

        <Directory /var/www/laravel/public>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/laravel-error.log
        CustomLog ${APACHE_LOG_DIR}/laravel-access.log combined

    </VirtualHost>
EOF

    log_progress "disable 000-default.conf.." "$TASK3_LOG" "true"
    sudo a2dissite 000-default.conf

    log_progress "enable laravel.conf..." "$TASK3_LOG" "true"
    sudo a2ensite laravel.conf

    log_progress "Task 3 executing..." "$TASK3_LOG" "true"
    apache2ctl -t

    log_progress "systemctl restart apache2..." "$TASK3_LOG" "true"
    sudo systemctl restart apache2

    sudo touch /var/www/laravel/database/database.sqlite
    sudo chown www-data:www-data /var/www/laravel/database/database.sqlite
    cd /var/www/laravel/

    log_progress "php artisan migrate" "$TASK3_LOG" "true"
    sudo php artisan migrate

    log_progress "php artisan db:seed" "$TASK3_LOG" "true"
    sudo php artisan db:seed

    log_progress "systemctl restart apache2" "$TASK3_LOG" "true"
    sudo systemctl restart apache2

    log_progress "Task 3 completed." "$TASK3_LOG" "true"
}

# Execute tasks
task_1
task_2
task_3

