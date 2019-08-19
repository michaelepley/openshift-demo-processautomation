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

: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_MAJOR?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_MAJOR"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_MINOR?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_MINOR"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_BRANCH?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_BRANCH"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_REGISTRY?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_REGISTRY"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_PREFIX?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_PREFIX"}
: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME?"missing configuration for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME"}
echo "OK"

echo "Creating process automation manager demo application"

OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config >/dev/null 2>&1
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE || { echo "FAILED: Could not login" && exit 1; }
popd >/dev/null 2>&1

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "	--> checking prerequisites"
# See https://access.redhat.com/terms-based-registry/#/token/mepley-service-account/openshift-secret
# and download token at https://access.redhat.com/terms-based-registry/#/token/mepley-service-account/openshift-secret
# login to docker at docker login -u='5318211|mepley-service-account' -p=eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiI1YmM5Y2FjMGFiZDY0ZTc2YWJhZjM4MTI2NjU4Y2VmMiJ9.pmuoGanCZNE8FO4jeZyum3pwgcYwOhglrBUYIqhORQY2y2ZWZG16Ld1NBS1C4yRkmvHNSm1My4oQf2d08H4_Vtai_AtkiJvwQKzeC_vNtpf4ttbxYNOFMVeHEX6uLbfsqTJ6bSpEl6t7di4WdcD4oDu7GwsU_fug-z7ey5gCplz7JhN5LGbNBH-HuSSeqcXagxGMhgTKwT_aLxLBL9sodDaAYcu4o2WReMFaRHzMnXAmzTWybW9w5DvfnfDMxRHJUYFbqy5CqL5VQTAVJBg7D7ony86lxW7mW0-VDCUrlauJUw_eG97zF1BhPxo8jJJAOpVGNgFmk3ITztijIOries_mqT0rNLbPbRDrzzaeyw4G4E-3c6QUuIEquHQxNFyijk_QfN7j5Ae-0uZh6bE32tkeDi2T5Qve-N66spbs5mY0VVYvHsoLP8v7_HMKXIuEkxqRCrjuK_2p4uUIP4l6UhY4pKtp-Z8azuaaAtCwoyk4SbviwHwTxNs6CCzkdANL3rqV5L81fIIy4jxevdtLGqfrIMlow75lMUzIvQVJ3DodVUvgzw_DQ_l-rspIEH-q88OFv689EkSjhl1a_Vkd3qx4BA7c1xtaMPV_8y8Z28Xx_z9q0zchQ7KTsBkm0kJTjRHqJrMHZ_Lgs0RKQbIvOX1_AYhFwbyXIZSCUscSj_o registry.redhat.io
echo "		--> Red Hat image registry access via pull secret"
oc get secret 5318211-mepley-service-account-pull-secret || { [ -f resources/mepley-service-account-secret.yaml ] && oc create -f resources/mepley-service-account-secret.yaml || { echo "FAILED: Could not create or validate Red Hat image registry access" && { return || exit ; } ; } ; }
oc secrets link default 5318211-mepley-service-account-pull-secret --for=pull || { echo "FAILED: could not link necessary pull secret" && { return || exit ; } ; }

echo "		--> Process Automation Manager Images"
# todo: extract images from templates that are acquired, as that is the canonical source for images that are actually used
# for rhpam70: OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES=(${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-businesscentral-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-kieserver-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-smartrouter-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-businesscentral-monitoring-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-controller-openshift )
OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES=(${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-businesscentral-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-kieserver-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-smartrouter-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-businesscentral-monitoring-openshift ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-controller-openshift )
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE in ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES[*]} ; do
	echo -n "		--> checking for ImageStream ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} " && { oc get is ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} -n openshift >/dev/null 2>&1 || oc get is ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} >/dev/null 2>&1 || oc import-image ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} --from=${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_REGISTRY}/${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_PREFIX}-${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_MAJOR}/${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE} --confirm >/dev/null 2>&1 && echo "...Found" ; } || { echo "FAILED: could not import decision central image " && exit 1 ; }
done

echo "	--> retagging image streams for convenience"
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM in ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGES[*]} ; do
	oc tag ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}:1.1 ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}:latest || echo "WARNING: could not retag image stream ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGESTREAM}"
done

echo "	--> creating the process automation manager templates"
# get the list of available branches from github via GET /repos/:owner/:repo/branches/:branch -- > GET repos/jboss-container-images/rhpam-7-openshift-image/branches/
##readarray OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS <<< `curl -sS -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-$(echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY})}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/jboss-container-images/rhpam-7-openshift-image/contents/templates" | jq -r '.[] | select( .type == "file" ) | .download_url' 2> /dev/null ` || { echo "FAILED: could not create fork of the application git repositories" && exit 1 ; }
# get the list of available templates from github via GET /repos/:owner/:repo/contents/:path?ref=:ref -- > GET repos/jboss-container-images/rhpam-7-openshift-image/contents/templates?ref=7.5
readarray OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS <<< `curl -sS -X GET -H "Accept: application/vnd.github.v3+json" -H "Authorization: token ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_PLAINTEXT:-$(echo ${GITHUB_AUTHORIZATION_TOKEN_OPENSHIFT_DEMO_CIPHERTEXT} | openssl enc -d -a -aes-256-cbc -k ${SCRIPT_ENCRYPTION_KEY})}" -H "Content-Type: application/json" -d '' "https://api.github.com/repos/jboss-container-images/rhpam-7-openshift-image/contents/templates?ref=${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_VERSION_BRANCH}" | jq -r '.[] | select( .type == "file" ) | .download_url' 2> /dev/null ` || { echo "FAILED: could not create fork of the application git repositories" ; }

echo "		--> available templates: ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS[*]} "
mkdir -p resources
pushd resources >/dev/null 2>&1
for OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL in ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURLS[*]} ; do
	echo -n "		--> downloading application template from ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL}..."
	OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE=`curl -sS -w %{filename_effective} -O ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATES_DOWNLOADURL}`
	echo "	--> ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE}"
	OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME=`cat ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} | yq -r '.metadata.name'`
	echo "		--> processing template truen ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME}"
	oc get template ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} -n openshift >/dev/null 2>&1 || oc get template ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} >/dev/null 2>&1 || oc create -f ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} -n openshift >/dev/null 2>&1 || oc create -f ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE} >/dev/null 2>&1 || { echo "FAILED: Could not create ${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_TEMPLATE_NAME} template " && exit 1 ; }
	
	#	oc get template rhpam70-kieserver-s2i -n openshift || oc create -f https://raw.githubusercontent.com/jboss-container-images/rhpam-7-openshift-image/rhpam70/templates/rhpam70-kieserver-s2i.yaml -n openshift  || { echo "FAILED: Could not create process automation manager template " && exit 1 ; }
done
popd >/dev/null 2>&1

echo "	--> Creating the necessary authentication objects"
APPLICATION_PROCESS_AUTOMATION_MANAGER_AUTH_RESOURCES_NAME_ROOT=auth-pam-server
APPLICATION_PROCESS_AUTOMATION_MANAGER_CLIENT_AUTH_RESOURCES_NAME_ROOT=auth-pam-client
APPLICATION_KIESERVER_AUTH_RESOURCES_NAME_ROOT=auth-kie-server
APPLICATION_KIESERVER_CLIENT_AUTH_RESOURCES_NAME_ROOT=auth-kie-client
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

# oc new-app rhpam70-trial-ephemeral -p APPLICATION_NAME=tempserver -p IMAGE_STREAM_TAG=latest -p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT} || { echo 'FAILED: Could not create process automation manager (aka kie server) ' && exit 1 ; }
oc get dc/process-automation-manager-kieserver || \
oc new-app --template=${OPENSHIFT_APPLICATION_PROCESS_AUTOMATION_MANAGER_IMAGE_BASENAME}-authoring \
			-p APPLICATION_NAME=${APPLICATION_NAME} \
			-p IMAGE_STREAM_NAMESPACE=${OPENSHIFT_PROJECT} \
			-p IMAGE_STREAM_TAG="latest" \
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

# precise tag
#			-p IMAGE_STREAM_TAG="1.1" \


# default secrets
#      -p BUSINESS_CENTRAL_HTTPS_SECRET="businesscentral-app-secret" \
#      -p KIE_SERVER_HTTPS_SECRET="kieserver-app-secret" \

# description: Default secret file with name 'jboss' and password 'mykeystorepass'

# make sure the service is exposed
# oc expose svc/rhpam70-kieserver

echo "	--> Creating test client application "
#oc new-app eap64-basic-s2i -p SOURCE_REPOSITORY_URL=https://github.com/jboss-container-images/rhdm-7-openshift-image.git -p SOURCE_REPOSITORY_REF=rhpam70-dev -p CONTEXT_DIR=quickstarts/hello-rules || { echo "FAILED: Could not create test client application" && exit 1 ; }

echo "Done."
