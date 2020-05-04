# Data source notes

**May 3, 2020**

It looks like the intended workflow for creating a dataset is for gni to fetch a tarball of a given data source, import certain parts of it into the MySQL database, and then perform matches against it.

Data sources are in a format called "Darwin Core" and there is a module that imports Darwin Core files at `app/models/dwca_importer.rb`. The [Darwin Core](https://dwc.tdwg.org/) site has more info. It appears that gni is using a particular flavor of Darwin Core called a "Darwin Core Archive" or [DwC-A](https://github.com/gbif/ipt/wiki/DwCAHowToGuide).

The file at `script/gni/make_source.rb` calls `DwcaImporter.create`, which is defined in `app/models/dwca_importer.rb`. It relies on a gem called [`dwc-archive`](https://rubygems.org/gems/dwc-archive/versions/1.0.1), which apparently was written by Dmitry Mozzherin, the gni developer.

## Using local data sources

Example data source: [http://www.catalogueoflife.org/DCA_Export/zip/archive-kingdom-plantae-phylum-tracheophyta-bl3.zip](http://www.catalogueoflife.org/DCA_Export/zip/archive-kingdom-plantae-phylum-tracheophyta-bl3.zip)

The `DwcaImporter` class expects to download datasources over http from a gzipped tarball, or `.tar.gz`. file. To replicate this workflow, we can make a `.tar.gz` archive of the datasource and then serve it locally using a Docker image.

### About `tar`

`tar` is the Linux tool for creating `.tar` archives. Check if you have `tar` installed by doing: `which tar`. If you need to install `tar`, one way to install it is to use homebrew to install `gnu-tar` by running `brew install gnu-tar`. Then, when you see `tar` in the following commands, type `gtar` instead. This page has [usage examples for `tar`](https://www.tecmint.com/18-tar-command-examples-in-linux/).

### Add a local data source

1. Download the .zip file of the datasource, then uncompress the .zip file into its original folder. On a Mac you do this by simply double-clicking the .zip file in Finder.
2. Use `tar cvzf` to create a gzipped tarball within the `config/docker/static-file-server/web/files` folder. This folder has been added to `.gitignore`, so it will not be included in git commits. Here is an example of how you would run the command.
    ```
    tar cvzf config/docker/static-file-server/archive-kingdom-plantae-phylum-tracheophyta-bl3.tar.gz archive-kingdom-plantae-phylum-tracheophyta-bl3
    ```
    In this example, the first argument following the `tar cvzf` command is the output destination, which ends in `.tar.gz`. The second argument is the input folder. This command was run from within the root of the gni repo.
3. Make note of the URL for your new tarball.  As you can see in the `docker-compose.yml` file, the `static-file-server` service is set up to serve any file within `config/docker/static-file-server/web` at port 8080. You can verify this by viewing [http://localhost:8080](http://localhost:8080), which shows you the index.html file at config/docker/static-file-server/web/index.html. This is how you can access a file from outside of a Docker container; however, networking **within** a Docker container works differently. To access a file in the static file server from inside of a different Docker container, you can use the name that Docker assigns to the containers. To see a list of running containers, do: `docker ps`. You should see something like this:
    ```
    CONTAINER ID        IMAGE                                  COMMAND                  CREATED             STATUS              PORTS                            NAMES
    1b6c86a150cb        gni_app                                "/bin/sh -c 'tail -f…"   8 minutes ago       Up 8 minutes        3000/tcp, 0.0.0.0:3000->80/tcp   gni_app_1
    0463f4bdbb33        gnames/solr                            "/bin/bash -c '/usr/…"   About an hour ago   Up 8 minutes        0.0.0.0:8983->8983/tcp           gni_solr_1
    4c0a4818e20f        halverneus/static-file-server:latest   "/serve"                 About an hour ago   Up 8 minutes        0.0.0.0:8080->8080/tcp           gni_static-file-server_1
    1b8de4113e10        mysql:5.6                              "docker-entrypoint.s…"   About an hour ago   Up 8 minutes        0.0.0.0:3307->3306/tcp           gni_db_1
    ```

    The NAMES column shows `gni_static-file-server_1` is the name for our static file service, so we use that as the hostname for the URL. In our example, the final URL will be:
    ```
    gni_static-file-server_1:8080/files/archive-kingdom-plantae-phylum-tracheophyta-bl3.tar.gz
    ```
4. Create a data source in `script/gni/make_source.rb`, following the format you see in the commented lines. Our example looks like this:
    ```
    ds = DataSource.create(title: "Tracheophyta")
    url = "gni_static-file-server_1:8080/files/archive-kingdom-plantae-phylum-tracheophyta-bl3.tar.gz"
    di = DwcaImporter.create(data_source:ds, url:url)
    di.import
    ```
5. Run the `make_source.rb` script to create a data source from the tarball.
    1. Do `docker exec -it gni_app_1 /bin/bash` to access a Bash command line within the `app` container.
    2. Run the script: `ruby script/gni/make_source.rb`. If everything is working, you will some output that looks like this:
    ```
    root@9849c0acddeb:/app# ruby script/gni/make_source.rb
    ********************WARNING: COULD NOT LOAD PRODUCTION_GNI_SITE FILE***********************
    [deprecated] I18n.enforce_available_locales will default to true in the future. If you really want to skip validation of your locale you can set I18n.enforce_available_locales = false to avoid this message.
    DwcaImporterLog|8|Import started for data source Tracheophyta
    DwcaImporterLog|8|Reading metadata
    DwcaImporterLog|8|Started normalization of the classification
    DwcaImporterLog|8|Reading core data
    DwcaImporterLog|8|Ingested 10000 records from core
    DwcaImporterLog|8|Ingested 20000 records from core
    DwcaImporterLog|8|Ingested 30000 records from core
    # more updates follow...
    ```

### Notes on debugging progress

#### May 4, 2020

At this point, we have the data source imported, but it looks like there is some issue with the Solr service. If you watch the output of startup.sh, you will notice this:
```
/app/lib/gni/solr_core.rb:110:in `get_rows': undefined method `id' for nil:NilClass (NoMethodError)
	from /app/lib/gni/solr_core.rb:61:in `ingest'
	from /app/script/gni/solr_import.rb:10:in `block in <main>'
	from /app/script/gni/solr_import.rb:7:in `each'
	from /app/script/gni/solr_import.rb:7:in `<main>'
```

I think this is because of some issue with the way that the Docker container for Solr is configured. The image was created by the developer, Dmitry: [gnames/solr](https://hub.docker.com/r/gnames/solr) and is characteristically cryptic. The error traces back to lib/gni/solr_core.rb, where the `get_rows` method tries to select something with the `CanonicalForm.select` method.
