echo "Set up external resources"

echo "	--> set up an external Identity store for storing the canonical user and system identities"

touch ./setup-identity-service-RHDS.sh

echo "	--> set up an external RHSSO for managing authentication and authorization"

touch  ./setup-sso-service-RHSSO.sh

echo "	--> set up an external HA Postgresql database for storing PAM's internal data"

touch ./setup-database-service-pgsql.sh

echo "	--> set up an external GIT repository for storing PAM business logic"

touch ./setup-scm-service-gogs.sh

echo "	--> set up an external Maven repository for storing PAM built artifacts"

touch ./setup-artifactrepo-service-nexus3.sh

echo "	--> modify PAM to use these new external resources"
# TODO: pause deployment triggers so we can update a handful of items independently, then reenable
# oc set env dc/rhpam-businesscentral BUSINESS_CENTRAL_MAVEN_USERNAME=businesscentraluser BUSINESS_CENTRAL_MAVEN_PASSWORD='password1!'

echo "Done."