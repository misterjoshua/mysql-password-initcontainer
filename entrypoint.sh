#!/bin/sh

INIT_DIR=${INIT_DIR:=/mysql-init}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:=root}
MYSQL_DATABASE=${MYSQL_DATABASE:=user}
MYSQL_USER=${MYSQL_USER:=user}
MYSQL_PASSWORD=${MYSQL_PASSWORD:=userpass}

mkdir -p "$INIT_DIR"

echo "Generating 5.5-plus set password script."
cat >"$INIT_DIR/set-passwords-5.5plus.sql" <<EOF
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');
SET PASSWORD FOR 'root'@'%' = PASSWORD('$MYSQL_ROOT_PASSWORD');

GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
FLUSH PRIVILEGES;
EOF

echo "Generating 5.7-plus set password script."
cat >"$INIT_DIR/set-passwords-5.7plus.sql" <<EOF
CREATE USER IF NOT EXISTS 'root'@'localhost', 'root'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';
ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';

CREATE USER IF NOT EXISTS '$MYSQL_USER'@'localhost', '$MYSQL_USER'@'%';
ALTER USER '$MYSQL_USER'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';
ALTER USER '$MYSQL_USER'@'%' IDENTIFIED WITH mysql_native_password BY '$MYSQL_PASSWORD';

GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'localhost', '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "Generated files"
find "$INIT_DIR" -type f