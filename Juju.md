# Juju Commands

| Command                           | Description                                                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------- |
| `juju status`                     | Reports the current status of the model, machines, applications and units                     |
| `watch -c juju status --color`    | Tracks the deployment process live                                                            |
| `juju deploy`                     | Deploys a new application or bundle                                                           |
| `juju add-unit`                   | Adds one or more units to a deployed application                                              |
| `juju add-credential`             | Adds or replaces credentials for a cloud, stored locally on this client                       |
| `juju list-credentials`           | Lists locally stored credentials for a cloud                                                  |
| `juju add-model`                  | Adds a hosted model                                                                           |
| `juju list-models`                | Lists models a user can access on a controller                                                |
| `juju run-action`                 | Queue an action for execution. E.g. `juju run-action kubernetes-worker/0 microbot replicas=5` |
| `juju upgrade-charm {CHARM_NAME}` | Upgrade an application's charm                                                                |
| `juju config {APPLICATION_NAME}`  | Gets, sets, or resets configuration for a deployed application                                |
