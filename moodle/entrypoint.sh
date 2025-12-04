#!/bin/bash
set -e

MOODLE_SRC="/usr/src/moodle"
WORKDIR="." # /var/www/html/moodle

# Wait until the database is ready
until mysqladmin ping -h"$MOODLE_DB_HOST" -u"$MOODLE_DB_USER" -p"$MOODLE_DB_PASSWORD" --silent --ssl=0; do
    printf '⏳\t%s\n' "Waiting until MySQL is ready..."
    sleep 2
done

# Clone Moodle source code if needed
if [ ! -f "$MOODLE_SRC"/version.php ]; then
	printf '🔨\t%s\n' "Performing git clone https://github.com/moodle/moodle.git from branch $MOODLE_BRANCH..."

	# Optimized to perform as fast as possible
    git clone \
    	--progress \
    	--branch "$MOODLE_BRANCH" \
    	--single-branch \
    	--depth 1 \
    	--no-tags \
    	-c http.extraheader="Accept: application/vnd.github.v3.raw" \
    	https://github.com/moodle/moodle.git \
    	"$MOODLE_SRC"

	printf '✅\t%s\n' "Moodle source code cloned successfully."
else
    printf '✅\t%s\n' "Moodle source code already exists in the internal volume."
fi

# Install Moodle automatically if needed
if [ ! -f "$MOODLE_SRC"/config.php ]; then
    printf '🔨\t%s\n' "Installing Moodle..."

    php "$MOODLE_SRC"/admin/cli/install.php \
        --wwwroot="$MOODLE_URL" \
        --dataroot="/var/moodledata" \
        --dbtype="mariadb" \
        --dbhost="$MOODLE_DB_HOST" \
        --dbport="$MOODLE_DB_PORT" \
        --dbname="$MOODLE_DB_NAME" \
        --dbuser="$MOODLE_DB_USER" \
        --dbpass="$MOODLE_DB_PASSWORD" \
        --fullname="Moodle Site" \
        --shortname="Moodle" \
        --adminuser="$MOODLE_ADMIN_USER" \
        --adminpass="$MOODLE_ADMIN_PASSWORD" \
        --agree-license \
        --non-interactive

    # Set correct permissions for config.php
    chown www-data:www-data "$MOODLE_SRC"/config.php
    chmod 644 "$MOODLE_SRC"/config.php

    printf '✅\t%s\n' "Moodle installed successfully."
else
    printf '✅\t%s\n' "Moodle already installed."
fi

# Sync Moodle installation into the WORKDIR, without overriding plugins
printf '🔨\t%s\n' "Syncing Moodle installation into the working directory $(realpath "$WORKDIR")"

rsync \
	-a \
	--ignore-existing \
	--exclude='.git' \
	--info=name \
	"$MOODLE_SRC/" \
	"$WORKDIR/"

printf '✅\t%s\n' "Moodle installation synced successfully."

# Run apache daemon after Moodle is guaranteed to be installed and served in the WORKDIR
exec apache2-foreground
