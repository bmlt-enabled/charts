# charts

https://charts.bmlt.app

`helm repo add bmlt https://charts.bmlt.app`

`helm search repo bmlt`

`helm install <release> bmlt/bmlt-root-server -n <namespace>`

* To deploy mysql to cluster you can do the following at minimum
    values yaml
    ```yaml
    auth:
      rootPassword: rootserver
      database: rootserver
      username: rootserver
      password: rootserver
    ```
    `helm repo add bitnami https://charts.bitnami.com/bitnami`
    `helm install -f values.yaml mysql bitnami/mysql -n <namespace>`

* If using alb for ingress you will need to make sure  AWS Load Balancer Controller is installed on cluster.
