#!/usr/bin/env bash

# See registry.access.redhat.com/rhpam-7/rhpam70-businesscentral-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-kieserver-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-smartrouter-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-businesscentral-monitoring-openshift
# See registry.access.redhat.com/rhpam-7/rhpam70-controller-openshift  

# See https://github.com/jboss-container-images/rhpam-7-openshift-image/tree/7.0.x/quickstarts/library-process
# See https://developers.redhat.com/products/rhpam/hello-world/#fndtn-process-automation-manager-on-openshift
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

# a base container that already has java and related tools + the "oc" command line tools built in
oc import-image openshift/jenkins-slave-maven-rhel7 -n openshift --from=registry.access.redhat.com/openshift3/jenkins-slave-maven-rhel7 --confirm

# a base container that already as the "oc" command line tools built in
oc import-image openshift/origin:v3.9.0 - n openshift --from=openshift/origin:v3.9.0 --confirm

echo "	--> creating custom images for installer"

oc new-build --strategy=docker --image-stream=openshift/redhat-openjdk18-openshift --dockerfile=$'FROM scratch\nUSER 0\nRUN yum clean all && yum install --disablerepo=* --enablerepo rhel-7-server-rpms --enablerepo rhel-7-server-ose-3.9-rpms -y unzip atomic-openshift-clients' --to=rhpam-installer-1 --allow-missing-imagestream-tags=true

oc new-build --strategy=docker --image-stream=rhpam-installer-1 --dockerfile=$'FROM scratch\nUSER 1001' --to=rhpam-installer --allow-missing-imagestream-tags=true


echo "Done."

