# Data source notes

**May 3, 2020**

It looks like the intended workflow for creating a dataset is for gni to fetch a tarball of a given data source, import certain parts of it into the MySQL database, and then perform matches against it.

Data sources are in a format called "Darwin Core" and there is a module that imports Darwin Core files at `app/models/dwca_importer.rb`. The [Darwin Core](https://dwc.tdwg.org/) site has more info. It appears that gni is using a particular flavor of Darwin Core called a "Darwin Core Archive" or [DwC-A](https://github.com/gbif/ipt/wiki/DwCAHowToGuide).

The file at `script/gni/make_source.rb` calls `DwcaImporter.create`, which is defined in `app/models/dwca_importer.rb`. It relies on a gem called [`dwc-archive`](https://rubygems.org/gems/dwc-archive/versions/1.0.1), which apparently was written by Dmitry Mozzherin, the gni developer.

## How to add a local data source

Example data source: [http://www.catalogueoflife.org/DCA_Export/zip/archive-kingdom-plantae-phylum-tracheophyta-bl3.zip](http://www.catalogueoflife.org/DCA_Export/zip/archive-kingdom-plantae-phylum-tracheophyta-bl3.zip)

The `DwcaImporter` class expects to download datasources over http from a gzipped tarball, or `.tar.gz`. file. To replicate this workflow, we can make a `.tar.gz` archive of the datasource and then serve it locally using a Docker image.

Check if you have `tar` installed by doing: `which tar`. If you need to install `tar`, one way to install it is to use homebrew to install `gnu-tar` by running `brew install gnu-tar`. Then, when you see `tar` in the following commands, type `gtar` instead. This page has [usage examples for `tar`](https://www.tecmint.com/18-tar-command-examples-in-linux/).

1. Download the .zip file of the datasource, then uncompress the .zip file into its original folder. On a Mac you do this by simply double-clicking the .zip file in Finder.
2. Use `tar cvzf` to create a gzipped tarball within the `config/docker/static-file-server` folder. This folder has been added to `.gitignore`, so it will not be included in git commits. Here is an example of how you would run the command.
```
tar cvzf config/docker/static-file-server/archive-kingdom-plantae-phylum-tracheophyta-bl3.tar.gz archive-kingdom-plantae-phylum-tracheophyta-bl3
```
In this example, the first argument following the `tar cvzf` command is the output destination, which ends in `.tar.gz`. The second argument is the input folder. This command was run from within the root of the gni repo.




