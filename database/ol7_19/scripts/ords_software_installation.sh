echo "******************************************************************************"
echo "Unpack all the software." `date`
echo "******************************************************************************"
# Java
mkdir -p /u01/java
cd /u01/java
tar -xzf ${SOFTWARE_DIR}/${JAVA_SOFTWARE}
TEMP_FILE=`ls`
ln -s ${TEMP_FILE} latest
# Tomcat
mkdir -p /u01/tomcat
cd /u01/tomcat
tar -xzf ${SOFTWARE_DIR}/${TOMCAT_SOFTWARE}
TEMP_FILE=`ls`
ln -s ${TEMP_FILE} latest
# CATALINA_BASE
mkdir -p ${CATALINA_BASE}
cp -r ${CATALINA_HOME}/conf $CATALINA_BASE
cp -r ${CATALINA_HOME}/logs $CATALINA_BASE
cp -r ${CATALINA_HOME}/temp $CATALINA_BASE
cp -r ${CATALINA_HOME}/webapps $CATALINA_BASE
cp -r ${CATALINA_HOME}/work $CATALINA_BASE
# ORDS
mkdir -p ${ORDS_CONF}
cd ${ORDS_HOME}
unzip -oq ${SOFTWARE_DIR}/${ORDS_SOFTWARE}
# SQLcl
cd /u01
unzip -oq ${SOFTWARE_DIR}/${SQLCL_SOFTWARE}
cd ${SOFTWARE_DIR}
# APEX Images
rm -Rf ${CATALINA_BASE}/webapps/*
mkdir -p ${CATALINA_BASE}/webapps/i/
cp -R ${SOFTWARE_DIR}/apex/images/* ${CATALINA_BASE}/webapps/i/


echo "******************************************************************************"
echo "Prep the ORDS parameter file." `date`
echo "******************************************************************************"
cat > ${ORDS_HOME}/params/ords_params.properties <<EOF
db.hostname=${ORACLE_HOSTNAME}
db.port=${DB_PORT}
db.servicename=${DB_SERVICE}
#db.sid=
db.username=APEX_PUBLIC_USER
db.password=${APEX_PUBLIC_USER_PASSWORD}
migrate.apex.rest=false
plsql.gateway.add=true
rest.services.apex.add=true
rest.services.ords.add=true
schema.tablespace.default=${APEX_TABLESPACE}
schema.tablespace.temp=${TEMP_TABLESPACE}
standalone.mode=false
#standalone.use.https=true
#standalone.http.port=8080
#standalone.static.images=/home/oracle/apex/images
user.apex.listener.password=${APEX_LISTENER_PASSWORD}
user.apex.restpublic.password=${APEX_REST_PASSWORD}
user.public.password=${PUBLIC_PASSWORD}
user.tablespace.default=${APEX_TABLESPACE}
user.tablespace.temp=${TEMP_TABLESPACE}
sys.user=SYS
sys.password=${SYS_PASSWORD}
EOF


echo "******************************************************************************"
echo "Configure ORDS. Safe to run on DB with existing config." `date`
echo "******************************************************************************"
cd ${ORDS_HOME}
$JAVA_HOME/bin/java -jar ords.war configdir ${ORDS_CONF}
$JAVA_HOME/bin/java -jar ords.war
cp ords.war ${CATALINA_BASE}/webapps/


echo "******************************************************************************"
echo "Configure HTTPS." `date`
echo "******************************************************************************"
if [ ! -f ${KEYSTORE_DIR}/keystore.jks ]; then
  mkdir -p ${KEYSTORE_DIR}
  cd ${KEYSTORE_DIR}
  ${JAVA_HOME}/bin/keytool -genkey -keyalg RSA -alias selfsigned -keystore keystore.jks \
     -dname "CN=${HOSTNAME}, OU=My Department, O=My Company, L=Birmingham, ST=West Midlands, C=GB" \
     -storepass ${KEYSTORE_PASSWORD} -validity 3600 -keysize 2048 -keypass ${KEYSTORE_PASSWORD}
  sed -i -e "s|###KEYSTORE_DIR###|${KEYSTORE_DIR}|g" ${SOFTWARE_DIR}/server.xml
  sed -i -e "s|###KEYSTORE_PASSWORD###|${KEYSTORE_PASSWORD}|g" ${SOFTWARE_DIR}/server.xml
  cp ${SOFTWARE_DIR}/server.xml ${CATALINA_BASE}/conf/
fi;


echo "******************************************************************************"
echo "Restart everything." `date`
echo "******************************************************************************"
${SCRIPTS_DIR}/stop_all.sh
# Get rid of start, as this is none done using the service.
#${SCRIPTS_DIR}/start_all.sh
