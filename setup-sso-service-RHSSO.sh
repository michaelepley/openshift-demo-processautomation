#!/usr/bin/env bash

# Configuration
. ./config-demo-openshift-processautomation.sh || { echo "FAILED: Could not configure" && exit 1 ; }

# Additional Configuration
#None

APPLICATION_NAME=rhsso
OPENSHIFT_PROJECT_RHSSO=shared-${APPLICATION_NAME}
OPENSHIFT_PROJECT_RHSSO_DESCRIPTION="Red Hat SSO Shared Service"
local OPENSHIFT_PROJECT=${OPENSHIFT_PROJECT_RHSSO}
local OPENSHIFT_PROJECT_DESCRIPTION

echo -n "Verifying configuration ready..."
: ${APPLICATION_NAME?"missing configuration for APPLICATION_NAME"}

: ${OPENSHIFT_MASTER?"missing configuration for OPENSHIFT_MASTER"}
: ${OPENSHIFT_APPS?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_USER_REFERENCE?"missing configuration for OPENSHIFT_APPS"}
: ${OPENSHIFT_OUTPUT_FORMAT?"missing configuration for OPENSHIFT_OUTPUT_FORMAT"}
: ${CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY?"missing configuration for CONTENT_SOURCE_DOCKER_IMAGES_RED_HAT_REGISTRY"}

echo "OK"

echo "Creating Red Hat SSO shared service"

# TODO
# OPENSHIFT_PROJECT_DESCRIPTION_QUOTED=\'${OPENSHIFT_PROJECT_DESCRIPTION}\'

oc project ${OPENSHIFT_PROJECT_RHSSO} || oc new project ${OPENSHIFT_PROJECT_RHSSO} --display-name="RH SSO Shared Service"--skip-config-write=true || { echo "FAILED: could not find or create RH SSO project " && exit 1 ; }

echo "		--> setup Red Hat image registry access via pull secret"
oc get secret 5318211-mepley-service-account-pull-secret || { [ -f resources/mepley-service-account-secret.yaml ] && oc create -f resources/mepley-service-account-secret.yaml || { echo "FAILED: Could not create or validate Red Hat image registry access" && { return || exit ; } ; } ; }
oc secrets link default 5318211-mepley-service-account-pull-secret --for=pull || { echo "FAILED: could not link necessary pull secret" && { return || exit ; } ; }

echo "	--> Allow the main project to view resources in this project"
oc policy add-role-to-user view system:serviceaccount:${OPENSHIFT_PROJECT}:default

# using custom template to reference theme image stream and force using openshift namespace for postgresql
oc new-app -n ${OPENSHIFT_PROJECT_RHSSO} 
--template=sso73-x509-postgresql-persistent \
 -p SSO_ADMIN_USERNAME="admin" \
 -p SSO_ADMIN_PASSWORD="Redhat1!" \
 -p SSO_REALM="pam-realm"
 
echo "	--> Modify the deployment descriptor for the RH Process Automation Manager to use this authentication service"
echo "TODO"

echo "Done."


