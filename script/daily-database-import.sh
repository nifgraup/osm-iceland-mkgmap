#!/bin/bash

## Create temporary DB:

# drop tmp user
dropdb osmistmp
dropuser osmistmp

dropdb osmisdel
dropuser osmisdel

# Create db/user
echo Creating user/db
createuser osmistmp -w -S -D -R
createdb -E UTF8 -O osmistmp osmistmp
echo "alter user osmistmp encrypted password 'osmistmp';" | psql avar
psql -d osmistmp < /usr/share/postgresql/8.4/contrib/btree_gist.sql

# Create schema
echo Creating schema
cd /home/avar/src/osm.nix.is/osm-sites-rails_port

echo "development:"           > config/database.yml
echo "  adapter: postgresql" >> config/database.yml
echo "  database: osmistmp"  >> config/database.yml
echo "  username: osmistmp"  >> config/database.yml
echo "  password: osmistmp"  >> config/database.yml
echo "  host: localhost"     >> config/database.yml
echo "  encoding: utf8"      >> config/database.yml

# migrate!
nice -n 5 rake db:migrate

# Import Iceland.osm
echo Importing data
nice -n 5 osmosis --read-xml-0.6 /var/www/osm.nix.is/latest/Iceland.osm.bz2 --write-apidb-0.6 populateCurrentTables=yes host="localhost" database="osmistmp" user="osmistmp" password="osmistmp" validateSchemaVersion=no

## Rename it & delete

# old -> del
echo "Moving old -> del";
echo 'alter database osmis rename to osmisdel;' | psql avar
echo 'alter user osmis rename to osmisdel;' | psql avar

# tmp -> new
echo "Moving tmp ->new"
echo 'alter database osmistmp rename to osmis;' | psql avar
echo 'alter user osmistmp rename to osmis;' | psql avar
echo "alter user osmis encrypted password 'osmis';" | psql avar

# del old
dropdb osmisdel
dropuser osmisdel


