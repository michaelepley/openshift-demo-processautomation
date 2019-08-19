#!/usr/bin/env bash

# See https://github.com/OpenShiftDemos/nexus

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

oc get template -n openshift nexus2-persistent || oc get template nexus2-persistent || oc create -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus2-template.yaml || { echo "WARNING: could not find or import nexus 2 persistent template" ; }
oc get template -n openshift nexus2 || oc get template nexus2 || oc create -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus2-persistent-template.yaml  || { echo "WARNING: could not find or import nexus 2 template" ; }

oc get template -n openshift nexus3-persistent || oc get template nexus3-persistent || oc create -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus3-template.yaml  || { echo "WARNING: could not find or import nexus 3 persistent template" ; }
oc get template -n openshift nexus2 || oc get template nexus2 || oc create -f https://raw.githubusercontent.com/OpenShiftDemos/nexus/master/nexus3-persistent-template.yaml  || { echo "WARNING: could not find or import nexus 3 template" ; }

# oc new-app nexus3-persistent
oc new-app nexus3

echo "Done."
