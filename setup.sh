#!/usr/bin/env bash

# See registry.access.redhat.com/rhpam-7/rhpam70-businesscentral-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-kieserver-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-smartrouter-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-businesscentral-monitoring-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-controller-openshift  

# See https://github.com/jboss-container-images/rhpam-7-openshift-image/tree/7.0.x/quickstarts/library-process
# See https://developers.redhat.cohttps://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/1.1/example-app-secret-template.yamlm/products/rhpam/hello-world/#fndtn-process-automation-manager-on-openshift
# See https://www.codelikethewind.org/2017/10/30/how-to-create-a-custom-work-item-handler-in-jbpm/

# Configuration
. ./config-demo-openshift-processautomation.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Creating process automation manager demo application"

OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "	--> checking prerequisites"
OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME=registry.access.redhat.com/rhpam-7
OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES=(rhpam70-businesscentral-openshift rhpam70-kieserver-openshift rhpam70-smartrouter-openshift rhpam70-businesscentral-monitoring-openshift rhpam70-controller-openshift )
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE in ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES[*]} ; do
	oc get is ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} -n openshift >/dev/null 2>&1 || oc get is ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} >/dev/null 2>&1 || oc import-image ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} --from=${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}/${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} --confirm >/dev/null 2>&1 || { echo "FAILED: could not import decision central image " && exit 1 ; }
done

echo "	--> retagging image streams for convenience"
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM in rhpam70-businesscentral-indexing-openshift rhpam70-businesscentral-monitoring-openshift rhpam70-businesscentral-openshift rhpam70-controller-openshift rhpam70-kieserver-openshift rhpam70-smartrouter-openshift ; do
	oc tag ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}:1.1 ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}:latest || echo "WARNING: could not retag image stream ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}"
done

echo "	--> creating the process automation manager template"
# get the list of available templates from github via GET /repos/:owner/:repo/contents/:path -- > GET repos/jboss-container-images/rhpam-7-openshift-image/contents/templates
readarray OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS <<< `curl -sS -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-$(echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY})}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/jboss-container-images/rhpam-7-openshift-image/contents/templates" | jq -r '.[] | select( .type == "file" ) | .download_url' 2> /dev/null ` || { echo "FAILED: could not create fork of the application git repositories" && exit 1 ; }

echo "		--> available templates: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS[*]} "
mkdir -p resources
pushd resources >/dev/null 2>&1
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL in ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS[*]} ; do
	echo -n "		--> downloading application template from ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL}..."
	OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE=`curl -sS -w %{filename_effective} -O ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL}`
	echo "	--> ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE}"
	OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME=`cat ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} | yq -r '.metadata.name'`
	echo "		--> processing template ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME}"
	oc get template ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} -n openshift >/dev/null 2>&1 || oc get template ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} >/dev/null 2>&1 || oc create -f ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} -n openshift >/dev/null 2>&1 || oc create -f ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} >/dev/null 2>&1 || { echo "FAILED: Could not create ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} template " && exit 1 ; }
	
	#	oc get template rhpam70-kieserver-s2i -n openshift || oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/rhpam70/templates/rhpam70-kieserver-s2i.yaml -n openshift  || { echo "FAILED: Could not create process automation manager template " && exit 1 ; }
done
popd >/dev/null 2>&1

echo "	--> Creating the necessary authentication objects"
APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT=auth-pam-server
APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT=auth-pam-client
APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT=auth-kie-server
APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT=auth-kie-client
APPLICATION_SERVER_AUTH_RESOURCES_USERNAME=admin
APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD=password
## map to ? ${KIE_ADMIN_USER}/${KIE_ADMIN_PWD}

echo "		--> Creating the necessary authentication objects for the process automation manager"
echo "			--> Create a keystore for the SERVER"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks ] || keytool -genkeypair -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -keyalg RSA -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} -dname "CN=${APPLICATION_SERVER_AUTH_RESOURCES_USERNAME}" -keypass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} >/dev/null 2>&1 || { echo "FAILED: could not find or create the server keystore" && exit 1; }
echo "			--> Export the SERVER certificate from the keystore"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.cert ] || keytool -export -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could not find or create the server certificate" && exit 1; }
echo "			--> Create the CLIENT keystore"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks ] || keytool -genkeypair -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -keyalg RSA -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -dname "CN=${APPLICATION_SERVER_AUTH_RESOURCES_USERNAME}" -keypass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} >/dev/null 2>&1 || { echo "FAILED: could not find or create the client keystore" && exit 1; }
echo "			--> import the previous exported SERVER certificate into a CLIENT truststore"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts ] || echo yes |  keytool -import -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could not add the server certificate to the client truststore" && exit 1; }
echo "			--> So we can configure the server to explicitly trust the client, the clients certificate is exported from the keystore"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert ] || keytool -export -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED" && exit 1; }
echo "			--> Import the clients exported certificate into a SERVER truststore"
[ -f resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ts ] || echo yes | keytool -import -alias ${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could not import the client certificates into the server truststore " && exit 1; }
echo "			--> Verify the contents of the SERVER keystore"
[ "`keytool -list -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the server keystore" && exit 1
echo "			--> Verify the contents of the SERVER truststore"
[ "`keytool -list -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the server  truststore" && exit 1
echo "			--> Verify the contents of the CLIENT truststore"
[ "`keytool -list -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the client truststore" && exit 1
echo "			--> Verify the contents of the CLIENT keystore"
[ "`keytool -list -keystore resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} |  grep ${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the client keystore" && exit 1

echo "			--> create the secrets for the process automation manager"
oc get secret/processautomationmanager-secret 2>/dev/null || oc create secret generic processautomationmanager-secret --from-file=resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks --from-file=resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ts || { echo "FAILED: could not create the server secrets" && exit 1; }
echo "			--> create the secrets for the process automation manager clients"
oc get secret/processautomationmanager-secret-client 2>/dev/null || oc create secret generic processautomationmanager-secret-client --from-file=resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks --from-file=resources/${APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts || { echo "FAILED: could not create the server secrets" && exit 1; }


echo "		--> Creating the necessary authentication objects for the kie server"
echo "			--> Create a keystore for the SERVER"
[ -f resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks ] || keytool -genkeypair -keystore resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -keyalg RSA -alias ${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT} -dname "CN=${APPLICATION_SERVER_AUTH_RESOURCES_USERNAME}" -keypass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} >/dev/null 2>&1 || { echo "FAILED: could not find or create the server keystore" && exit 1; }
echo "			--> Export the SERVER certificate from the keystore"
[ -f resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.cert ] || keytool -export -alias ${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could not find or create the server certificate" && exit 1; }
echo "			--> Create the CLIENT keystore"
[ -f resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks ] || keytool -genkeypair -keystore resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -keyalg RSA -alias ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -dname "CN=${APPLICATION_SERVER_AUTH_RESOURCES_USERNAME}" -keypass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} >/dev/null 2>&1 || { echo "FAILED: could not find or create the client keystore" && exit 1; }
echo "			--> import the previous exported SERVER certificate into a CLIENT truststore"
[ -f resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts ] || echo yes |  keytool -import -alias ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could find or create the client truststore " && exit 1; }
echo "			--> So we can configure the server to explicitly trust the client, the clients certificate is exported from the keystore"
[ -f resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert ] || keytool -export -alias ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED" && exit 1; }
echo "			--> Import the clients exported certificate into a SERVER truststore --> resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ts "
[ -f resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ts ] || echo yes | keytool -import -alias ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} -keystore resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} -file resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.cert >/dev/null 2>&1 || { echo "FAILED: could not import the client certificates into the server truststore " && exit 1; }
echo "			--> Verify the contents of the SERVER keystore"
[ "`keytool -list -keystore resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the server  keystore" && exit 1
echo "			--> Verify the contents of the SERVER truststore"
[ "`keytool -list -keystore resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the server  truststore" && exit 1
echo "			--> Verify the contents of the CLIENT truststore"
[ "`keytool -list -keystore resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} | grep ${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the client truststore" && exit 1
echo "			--> Verify the contents of the CLIENT keystore"
[ "`keytool -list -keystore resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks -storepass ${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} |  grep ${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT} | wc -l >/dev/null 2>&1`" == 0 ] && echo "FAILED: could not verify the contents of the client keystore" && exit 1

echo "			--> create the secrets for the kie server"
oc get secret/kieserver-secret >/dev/null 2>&1 || oc create secret generic kieserver-secret --from-file=resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks --from-file=resources/${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ts >/dev/null 2>&1 || { echo "FAILED: could not create the server secrets" && exit 1; }
echo "			--> create the secrets for the kie server clients"
oc get secret/kieserver-secret-client >/dev/null 2>&1 || oc create secret generic kieserver-secret-client --from-file=resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ks --from-file=resources/${APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT}.ts >/dev/null 2>&1 || { echo "FAILED: could not create the server secrets" && exit 1; }


echo "	--> Creating process automation manager service accounts "
oc get sa/kieserver-service-account || oc create serviceaccount kieserver-service-account || { echo "FAILED: Could not create service account template " && exit 1 ; }
oc get sa/processautomationmanager-service-account || oc create serviceaccount processautomationmanager-service-account || { echo "FAILED: Could not create service account template " && exit 1 ; }

echo "	--> Linking process automation manager service accounts to generated secrets "
oc secrets link sa/processautomationmanager-service-account secret/processautomationmanager-secret
oc secrets link sa/kieserver-service-account secret/kieserver-secret

echo "	--> Creating process automation manager from template "

# KIE Parameters
APPLICATION_KIE_ADMIN_USER=pamAdmin
APPLICATION_KIE_ADMIN_PWD=redhatpam1!
APPLICATION_KIE_SERVER_CONTROLLER_USER=kieserver
APPLICATION_KIE_SERVER_CONTROLLER_PWD=kieserver1!
APPLICATION_KIE_SERVER_USER=kieserver
APPLICATION_KIE_SERVER_PWD=kieserver1!

# oc new-app rhpam70-trial-ephemeral -p APPLICATION_NAME=tempserver -p IMAGE_STREAM_TAG=latest -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT} || { echo 'FAILED: Could not create process automation manager (aka kie server) ' && exit 1 ; }
oc get dc/process-automation-manager-kieserver || \
oc new-app --template=rhpam70-authoring \
			-p APPLICATION_NAME=${APPLICATION_NAME} \
			-p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT} \
			-p IMAGE_STREAM_TAG="1.1" \
			-p KIE_ADMIN_USER=${APPLICATION_KIE_ADMIN_USER} \
			-p KIE_ADMIN_PWD=${APPLICATION_KIE_ADMIN_PWD} \
			-p KIE_SERVER_CONTROLLER_USER=${APPLICATION_KIE_SERVER_CONTROLLER_USER} \
			-p KIE_SERVER_CONTROLLER_PWD=${APPLICATION_KIE_SERVER_CONTROLLER_PWD} \
			-p KIE_SERVER_USER=${APPLICATION_KIE_SERVER_USER} \
			-p KIE_SERVER_PWD=${APPLICATION_KIE_SERVER_PWD} \
			-p BUSINESS_CENTRAL_HTTPS_SECRET=processautomationmanager-secret \
			-p BUSINESS_CENTRAL_HTTPS_KEYSTORE=${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT}.ks \
			-p BUSINESS_CENTRAL_HTTPS_NAME=${APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT} \
			-p BUSINESS_CENTRAL_HTTPS_PASSWORD=${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} \
			-p KIE_SERVER_HTTPS_SECRET=kieserver-secret \
			-p KIE_SERVER_HTTPS_KEYSTORE=${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT}.ks \
			-p KIE_SERVER_HTTPS_NAME=${APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT} \
			-p KIE_SERVER_HTTPS_PASSWORD=${APPLICATION_SERVER_AUTH_RESOURCES_PASSWORD} \
			-p BUSINESS_CENTRAL_MEMORY_LIMIT="2Gi"


# default secrets
#      -p BUSINESS_CENTRAL_HTTPS_SECRET="businesscentral-app-secret" \
#      -p KIE_SERVER_HTTPS_SECRET="kieserver-app-secret" \

# description: Default secret file with name 'jboss' and password 'mykeystorepass'


# oc expose svc/rhpam70-kieserver

echo "	--> Creating test client application "
#oc new-app eap64-basic-s2i -p SOURCE_REPOSITORY_URL=https://github.com/jboss-container-images/rhdm-7-openshift-image.git -p SOURCE_REPOSITORY_REF=rhpam70-dev -p CONTEXT_DIR=quickstarts/hello-rules || { echo "FAILED: Could not create test client application" && exit 1 ; }

echo "Done."
