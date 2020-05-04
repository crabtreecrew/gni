# Dockerizing Notes

The current approach is to run three separate Docker containers by using Docker Compose:
1. `app` is the Rails application, which is built from the `Dockerfile` at the project root
2. `solr` is an Apache Solr search platform used by `app`
3. `db` is a MySQL database used by `app`

## Work in progress

At the moment, the `docker-compose up` command is not quite complete. The goal is to be able to run this command and let Docker check to see if the databases exist. If not, they should be created, and then the database migrations should be run to set up the required database structure, and the seed data should be populated. Next, the Solr service should be set up and run, and then the Rails app should get served by `unicorn` and `nginx`.

I've started automating this by creating a Bash script at /config/docker/scripts/startup.sh, but it's not quite working yet because it can't create the databases on its own. See the notes in the Dockerfile for details. The workaround is to create the databases manually and then run /config/docker/scripts/startup.sh.

To run the GNI app with Docker Compose, do the following:

### Running with docker-compose: first time

1. If running for the first time, do `docker-compose up`. If you have made changes in the Dockerfile, do `docker-compose up --build` to rebuild. Wait until the logs stop populating; you should see this message when MySQL is ready for connections:
    ```
    db_1    | 2019-12-06 20:22:34 1 [Note] mysqld: ready for connections.
    ```
2. If running the app for the first time, you need to create the databases manually. In another terminal, do: `docker exec -it gni_db_1 mysql -uroot -p`. Enter the password "resolver" to log in. This gives you access to the MySQL command line. From here, run the following commands to create the databases:
    ```
    CREATE DATABASE gni CHARACTER SET utf8;
    CREATE DATABASE gni_dev CHARACTER SET utf8;
    CREATE DATABASE gni_test CHARACTER SET utf8;
    ```
3. In another terminal, do: `docker exec -it gni_app_1 /bin/bash`. This gives you access to a Bash command line in the `app` container. From here, run: `sh config/docker/scripts/startup.sh`. This is a Bash script that runs several other scripts to set up the MySQL and Solr services. You will see output as these tasks are run. The last  This script also starts up the [Unicorn](https://bogomips.org/unicorn/) server at the end. When the startup script is finished, you will see:
    ```
    STARTUP.SH: DONE
    ```
4. Unicorn requires a reverse proxy in front of it. We are using NGINX. In another terminal, do: `docker exec -it gni_app_1 /bin/bash`, then do `service nginx start`. Now that NGINX is running, the app should be up.

If it's working, you can go to [http://localhost:3000](http://localhost:3000) to see the running application.

### Running with docker-compose: coming back

If you have previously run the steps above, you can start things up again by doing the following:
1. `docker exec -it gni_app_1 /bin/bash`
2. `sh config/docker/scripts/startup.sh`
3. In another terminal window: `docker exec -it gni_app_1 /bin/bash` again
4. `service nginx start`

If it's working, you can go to [http://localhost:3000](http://localhost:3000) to see the running application.

### Issues

When running `sh config/docker/scripts/startup.sh`, we see this message repeated:
    ```
    ********************WARNING: COULD NOT LOAD PRODUCTION_GNI_SITE FILE***********************
    ```
    This is coming from config/environments/production.rb, which is trying to load a `.gitignore`d file. I can't find any notes on what this file is or what it contains.

### More on Docker and volumes

You only need to create the databases the first time you run `docker-compose up` because the docker-compose.yml file is set up with a volume called `db`, which persists beyond each run. You can wipe out this volume by running `docker-compose down -v`. The normal `docker-compose down` does not delete volumes. Here's a handy article about [how to clean up unused Docker images and containers](https://www.digitalocean.com/community/tutorials/how-to-remove-docker-images-containers-and-volumes).
