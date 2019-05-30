#!/usr/bin/env bash

# Configuration
. ./config-demo-openshift-processautomation.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_PROJECT?"missing configuration for OPENSHIFT_PROJECT"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_USER_REFERENCE"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}
echo "OK"

echo "Cleaning up sample PHP + MySQL demo application"
echo "	--> Make sure we are logged in (to the right instance and as the right user)"
pushd config
. ./setup-login.sh -r OPENSHIFT_USER_REFERENCE -n ${OPENSHIFT_PROJECT} || { echo "FAILED: Could not login" && exit 1; }
popd

[ "x${OPENSHIFT_CLUSTER_VERIFY_OPERATIONAL_STATUS}" != "xfalse" ] || { echo "	--> Verify the openshift cluster is working normally" && oc status -v >/dev/null || { echo "FAILED: could not verify the openshift cluster's operational status" && exit 1; } ; }

echo "	--> delete all openshift resources"
oc delete all -l app=${OPENSHIFT_APPLICATION_NAME}
# note: the secret is not labeled _or_ captured by the delete all above and must be expressly deleted
oc delete secret/processautomationmanager-secret secret/processautomationmanager-secret-client secret/kieserver-secret secret/kieserver-secret-client
oc secrets unlink sa/processautomationmanager-service-account secret/processautomationmanager-secret
oc secrets unlink sa/kieserver-service-account secret/kieserver-secret

oc delete sa/kieserver-service-account sa/processautomationmanager-service-account

echo "	--> delete all local artifacts"
rm -f resources/*.cert resources/*.ts resources/*.ks resources/*.yaml resources/*.json
echo "Done"
