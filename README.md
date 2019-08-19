# openshift-demo-processautomation


# Connection to RHSSO

I've done it a handful of times, although it's been a little while. A few things I'd suggest:
I would also set the BUSINESS_CENTRAL_MAVEN_USERNAME and BUSINESS_CENTRAL_MAVEN_PASSWORD parameters in your script. Without setting the username and password, the username will default and the password will be randomly generated. Although RH-SSO is where you will create the maven user and assign a password, those template params are still needed since the KIE Server(s) will have to know what to authenticate with.
Make sure that inside RH-SSO you have created all the users you need (including the maven user above!). When using RH-SSO, the application-users.properties and application-roles.properties are trumped. [1]
The users you've created above all need certain roles assigned inside RH-SSO, except for the maven user, who simply needs to be authenticated by RH-SSO. Examples of default roles that we set when not using RH-SSO and when the user did not specify them in a template are made via a script. [2] So you can use that as an example.
Best,
Davie

[1] https://github.com/jboss-container-images/jboss-kie-modules/blob/rhpam-7.3.1.GA/jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh#L179
[2] https://github.com/jboss-container-images/jboss-kie-modules/blob/rhpam-7.3.1.GA/jboss-kie-wildfly-common/added/launch/jboss-kie-wildfly-security.sh#L63 (also L89, L120, L164)

--
David Ward




Your advice was spot on David, thanks! Setting the those two parameters, BUSINESS_CENTRAL_MAVEN_USERNAME and BUSINESS_CENTRAL_MAVEN_PASSWORD and also creating the user in sso (no roles needed), worked.

If anyone is interested, this is the script I used to deploy with all the options needed.
https://github.com/mechevarria/ocp-pam/blob/master/sso-scripts/ocp-deploy-pam-sso.sh

This folder also has a realm export and sso deployment scripts if anybody wants to try it out
https://github.com/mechevarria/ocp-pam/tree/master/sso-scripts
