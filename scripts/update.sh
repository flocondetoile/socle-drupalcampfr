#!/bin/bash

FILE_PATH=$(realpath $0)
PROJECT_PATH=$(dirname $(dirname $FILE_PATH))

. $PROJECT_PATH/scripts/script-parameters.sh

# Test that composer is installed.
if ! hash "composer" 2> /dev/null; then
    echo "ERROR: Composer needs to be installed. Aborting.";
    exit 1;
fi

# Update source.
if [ "${ENVIRONMENT_MODE}" = "dev" ]; then
    composer install --working-dir=$WWW_PATH
else
    composer install --working-dir=$WWW_PATH --no-dev
fi

# Without drush alias, change temporarily directory to www.
cd $WWW_PATH

# Database backup.
$DRUSH sql-dump --result-file="${PROJECT_PATH}/backups/${CURRENT_DATE}.sql" --gzip

# Launch updates.
$DRUSH updb -y

# Enable development modules.
if [ "${ENVIRONMENT_MODE}" = "dev" ]; then
  $DRUSH en \
    dblog \
    devel \
    features_ui \
    field_ui \
    views_ui \
    webprofiler \
    -y
fi

# Revert features.
$DRUSH features-import -y --bundle=drupalcampfr core
$DRUSH features-import -y --bundle=drupalcampfr site
$DRUSH features-import -y --bundle=drupalcampfr user
$DRUSH features-import -y --bundle=drupalcampfr news

# Commented to not interfere with bootstrap block configs in bootstrap theme.
#$DRUSH fim -y --bundle=drupalcampfr drupalcampfr

# Create directory for csv files in public files.
mkdir -p $PROJECT_PATH/www/sites/default/files/csv

# Copy csv file into public directory.
for CSV_FILE in $(find $PROJECT_PATH/www/*/custom/* -type f -name "*.csv"); do
    cp -f $CSV_FILE $PROJECT_PATH/www/sites/default/files/csv/
done

# Import content.
$DRUSH migrate-import --group=drupalcampfr --update

# Back to the current directory.
cd $CURRENT_PATH
