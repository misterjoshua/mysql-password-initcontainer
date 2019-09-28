<img src="https://img.shields.io/docker/cloud/automated/wheatstalk/mysql-password-initcontainer" alt="Automated Build"> <img src="https://img.shields.io/docker/cloud/build/wheatstalk/mysql-password-initcontainer" alt="Build Status">

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
| File | Description |
| ---- | ----------- |
| `set-passwords-5.5plus.sql` | This file sets passwords for root and the secondary user for MySQL 5.5 and 5.6. |
| `set-passwords-5.7plus.sql` | This file works with MySQL 5.7 and 8.0 |

## Kubernetes Pod Example
In Kubernetes, you could add this image as an `initContainer`. In the example below, the MySQL root and user credentials are provided in a secret that was created with this command:

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