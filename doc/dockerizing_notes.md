# Dockerizing Notes

The current approach is to run three separate Docker containers by using Docker Compose:
1. `app` is the Rails application, which is built from the `Dockerfile` at the project root
2. `solr` is an Apache Solr search platform used by `app`
3. `db` is a MySQL database used by `app`

## Work in progress

At the moment, the `docker-compose up` command is not quite complete. The goal is to be able to run this command and let Docker check to see if the databases exist. If not, they should be created, and then the database migrations should be run to set up the required database structure, and the seed data should be populated. Next, the Solr service should be set up and run, and then the Rails app should get served by `unicorn`.

I've started automating this by creating a Bash script at /config/docker/scripts/startup.sh, but it's not quite working yet because it can't create the databases on its own. See the notes in the Dockerfile for details. The workaround is to create the databases manually and then run /config/docker/scripts/startup.sh.

To run the GNI app with Docker Compose, do the following:

1. If running for the first time, do `docker-compose up`. If you have made changes in the Dockerfile, do `docker-compose up --build` to rebuild. Wait until the logs stop populating; you should see this message when MySQL is ready for connections:
    ```
    db_1    | 2019-12-06 20:22:34 1 [Note] mysqld: ready for connections.
    ```
2. In another terminal, do: `docker exec -it gni_db_1 mysql -uroot -p`. Enter the password "resolver" to log in. This gives you access to the MySQL command line, where you can create the databases manually.
3. From here, run the following commands:
    ```
    CREATE DATABASE gni CHARACTER SET utf8;
    CREATE DATABASE gni_dev CHARACTER SET utf8;
    CREATE DATABASE gni_test CHARACTER SET utf8;
    ```
4. In another terminal, do: `docker exec -it gni_app_1 /bin/bash`. This gives you access to a Bash command line in the `app` container.
5. From here, run: `sh config/docker/scripts/startup.sh`

You will see that the database migrations run and the seed data is populated. However, the app is not quite working yet.

We should be able to go to http://localhost:3000 and see the running application, but we get no response right now. I believe there are a few possible causes:

- We see this message repeated:
    ```
    ********************WARNING: COULD NOT LOAD DEVELOPMENT_GNI_SITE FILE***********************
    ```
    This is coming from config/environments/development.rb. I'm not sure what this file is for and I haven't found it anywhere in the original repo.
- The URLs in docker-compose.yml look wrong to me:
    ```
      - SOLR_URL=http://solr:8983/solr
      - BASE_URL=http://0.0.0.0:3000
    ```
    I expect that there is a connection problem between the Docker containers because of this.
