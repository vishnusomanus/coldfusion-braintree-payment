## Compose sample application
### ColdFusion standalone application

Project structure:
```
.
├── docker-compose.yml
├── dockerfile
├── init.sql
├── mysql-connector-j-8.0.32.jar
├── app
    └── test.cfm
    └── dumpserver.cfm
    └── Application.cfm
    └── index.cfm
    └── Users.cfc

```
[_dockerfile_](dockerfile)
```
FROM adobecoldfusion/coldfusion2021:latest

COPY mysql-connector-j-8.0.32.jar /opt/coldfusion/cfusion/lib/mysql-connector-j-8.0.32.jar

# Expose MySQL port
EXPOSE 3333


# Install MySQL server and client
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -yq install mysql-server mysql-client

RUN service mysql start



```

[_docker-compose.yml_](docker-compose.yml)
```
version: "3"
services:
  coldfusion:
    container_name: mycoldfusion
    build: .
    ports:
      - "8555:8555"
    environment:
        - acceptEULA=YES
        - password=Pwd4cf!23
    volumes:
      - ./app:/app
    networks:
      - my_network
    depends_on:
        - mysql
    restart: on-failure

  mysql:
    container_name: mymysql
    image: mysql:latest
    command: --default-authentication-plugin=mysql_native_password
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: mydatabase
    ports:
      - "3333:3306"
    volumes:
      - ./mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - my_network
networks:
  my_network:

```

## Deploy with docker-compose

```
$ docker-compose up -d
- Network cf-latest_default         Created                                                                       0.8s
 - Container cf-latest-coldfusion-1  Created                                                                       0.2s
Attaching to cf-latest-coldfusion-1
cf-2021-latest-coldfusion-1  | Updating webroot to /app
cf-2021-latest-coldfusion-1  | Configuring virtual directories
cf-2021-latest-coldfusion-1  | Updating password
cf-2021-latest-coldfusion-1  | Serial Key: Not Provided       
cf-2021-latest-coldfusion-1  | Previous Serial Key: Not Provided
cf-2021-latest-coldfusion-1  | Starting ColdFusion
...
```

## Expected result


After the application starts, navigate to `http://localhost:8555` in your web browser to see available files in CF's default webroot (added to by the /app volume mapping). Mysql will be availabe on port 3333.

Or run `http://localhost:8555/test.cfm` in your web browser to see the test page in the mapped /app folder, or run via curl:
```
$ curl http://localhost:8555/test.cfm

Which will show:
Hello World! at 03-Oct-2021 02:25:44
```
Run this to see a dump of the server.coldfusion struct within the container: navigate to `http://localhost:8555/dumpserver.cfm` in your web browser or run:
```
$ curl http://localhost:8555/dumpserver.cfm
```
Coldfusion Demo CRUD application
```
$ http://localhost:8555
```
Coldfusion Administrator
```
$ http://localhost:8555/CFIDE/administrator/index.cfm
```

## Credentials

Coldfusion
    ```
    admin: Pwd4cf!23
    ```
Mysql
    ```
    root: root
    ```


Stop and remove the containers
```
$ docker-compose down
```