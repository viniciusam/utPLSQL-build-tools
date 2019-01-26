#!/bin/sh
set -ve

if [ -z $CONTAINER_NAME ]; then
  echo 'You must provide a container name!'
  exit 1
fi

if [ -z $UTPLSQL_VERSION ]; then
  UTPLSQL_VERSION=$(curl -s -i https://github.com/utPLSQL/utPLSQL/releases/latest | grep 'Location:' | awk -F'/' '{print $NF}' | tr -d '[:space:]')
  echo "No version specified, using latest: $UTPLSQL_VERSION"
fi

fileName="utPLSQL"

# Create a temporary install script.
cat > install.sh.tmp <<EOF
tar -xzf ${fileName}.tar.gz && rm ${fileName}.tar.gz
cd ${fileName}/source
sqlplus -S -L ${DBA_USERNAME}/${DBA_PASSWORD}@${CONNECTION_STR} AS SYSDBA @install_headless.sql ${UT3_OWNER} ${UT3_PASSWORD} ${UT3_TABLESPACE}
sqlplus -S -L ${DBA_USERNAME}/${DBA_PASSWORD}@${CONNECTION_STR} AS SYSDBA << SQL
grant execute any procedure to ${UT3_OWNER};
grant create any procedure to ${UT3_OWNER};
grant execute on dbms_lob to ${UT3_OWNER};
grant execute on dbms_sql to ${UT3_OWNER};
grant execute on dbms_xmlgen to ${UT3_OWNER};
grant execute on dbms_lock to ${UT3_OWNER};  
exit
SQL
EOF

# Download the requested version of utPLSQL.
curl -L -O "https://github.com/utPLSQL/utPLSQL/releases/download/$UTPLSQL_VERSION/$fileName.tar.gz"

# Copy utPLSQL files to the container and install it.
docker cp ./$fileName.tar.gz $CONTAINER_NAME:/$fileName.tar.gz
docker cp ./install.sh.tmp $CONTAINER_NAME:/install.sh

# Execute the utPLSQL installation inside the container.
docker exec $CONTAINER_NAME sh install.sh
