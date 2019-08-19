# Help for RH Process Automation Manager

## Documentation

Available Official documentation

- [Listing of all documentation](https://access.redhat.com/documentation/en-us/red_hat_process_automation_manager/)
- [Managing and monitoring the process server](https://access.redhat.com/documentation/en-us/red_hat_process_automation_manager/7.4/html-single/managing_and_monitoring_process_server/index)
- [KIE API docs](https://access.redhat.com/documentation/en-us/red_hat_process_automation_manager/7.4/html-single/interacting_with_red_hat_process_automation_manager_using_kie_apis/index)

## Enablement

### About

The official enablement for RH PAM (7.3 as of 2019-08-01). Currently designed for [RHPDS](rhpds.redhat.com)

### Enablement resources

[Red Hat internal Gitlab](https://gitlab.consulting.redhat.com/ddoyle/bxms_decision_mgmt_foundations)

### Points of Contact

## Knowledge Base Articles

This is a list of potentially useful KB articles

- https://access.redhat.com/solutions/2106041

## Internet resources

- [Container handling and updating](https://mswiderski.blogspot.com/2016/09/improved-container-handling-and-updates.html)
About upgrading OpenShift deployments - there is currently no specific upgrade mechanism, user should deploy new version using templates/APB/Operator and start using it.
For 7.5 there is going to be an upgrade support for Kie Operator [1].
About process upgrades, Kie server containers have capability to define an alias, which can be used for pointing to latest container version. You can find more informations about that on [2].
About process instance migration, Kie server has capability to migrate process from one version to another. I am not much familiar with the migration functionality, maybe Marian could tell you more about it.
- [Process Instance Migration (only for 7.4+)](https://access.redhat.com/documentation/en-us/red_hat_process_automation_manager/7.4/html/managing_and_monitoring_business_processes_in_business_central/process-instance-migration-con)
- [tbd](tbd)

## People

### PAM developers

- Tihomir Surdilovic
- Bernard Tison <btison@redhat.com>

### PAM marketing types

- Karina Varela, Senior Technical Marketing Manager LATAM, Middleware BU

### Third parties