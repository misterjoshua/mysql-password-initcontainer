<img src="https://img.shields.io/travis/misterjoshua/mysql-password-initcontainer" alt="Automated Build">

# MySQL Password Init Container
MySQL Password Init Container generates SQL files that set MySQL user passwords. The SQL we generate is useful to ensure that a MySQL instance has specific usernames and passwords through mysqld's `--init-file` argument, so that the passwords are set at least every time MySQL starts.

## Configuration
This image uses environment variables for its configuration. Here is a brief description of the variables available. All are currently mandatory as this image is a bit of a one-trick pony.

| Environment Variable | Description | Default |
| -------------------- | ----------- | ------- |
| `MYSQL_ROOT_PASSWORD` | Sets the `root` user password. | *root* |
| `MYSQL_USER` | The name of a secondary user that is granted `ALL` privileges on the database specified in the `MYSQL_DATABASE` variable. | *user* |
| `MYSQL_PASSWORD` | The password for the user created through `MYSQL_USER` | *userpass* |
| `MYSQL_DATABASE` | The name of the database that the secondary user is granted `ALL` privileges on. | *user* |

## Generated SQL files
Once the init container has finished, it will output SQL to `/mysql-init/`. To access the generated SQL in another container, you can mount an `emptyDir` at `/mysql-init/` on this image's container and share that volume with another container on the pod or task that contains a `mysqld`.

| File | Description |
| ---- | ----------- |
| `/mysql-init/set-passwords-5.5plus.sql` | This file sets passwords for root and the secondary user for MySQL 5.5 and 5.6. |
| `/mysql-init/set-passwords-5.7plus.sql` | This file works with MySQL 5.7 and 8.0 |

## Kubernetes Pod Example
In Kubernetes, you can add this image as an `initContainer`. In the example below, the MySQL root and user credentials are available through a secret resource that is created separately:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      initContainers:
        - name: mysql-init
          image: wheatstalk/mysql-password-initcontainer:VERSION
          imagePullPolicy: Always
          env:
          - name: MYSQL_ROOT_PASSWORD
            valueFrom:
              secretKeyRef: { name: mysql-secret, key: root-password }
          - name: MYSQL_USER
            valueFrom:
              secretKeyRef: { name: mysql-secret, key: user-name }
          - name: MYSQL_PASSWORD
            valueFrom:
              secretKeyRef: { name: mysql-secret, key: user-password }
          - name: MYSQL_DATABASE
            value: somedatabase
          volumeMounts:
          - mountPath: /mysql-init
            name: mysql-init
      containers:
      - name: mysql
        image: mysql:5.6
        # image: mysql:8
        args:
        - mysqld
        - --init-file=/mysql-init/set-passwords-5.5plus.sql
        # - --init-file=/mysql-init/set-passwords-5.7plus.sql
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef: { name: mysql-secret, key: root-password }
        ports:
        - containerPort: 3306
        volumeMounts:
        - mountPath: /mysql-init
          name: mysql-init
        - mountPath: /var/lib/mysql
          name: mysql-data
      volumes:
        - name: mysql-init
          emptyDir: {}
        - name: mysql-data
          # emptyDir: {}
          # persistentVolumeClaim: { claimName: "" }
          hostPath:
            path: /srv/mysql-data
```