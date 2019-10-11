This repository contains the code to import and integrate the book and rating data that we work with.
It imports and integrates data from several sources in a single PostgreSQL database; import scripts
are primarily in Python, with Rust code for high-throughput processing of raw data files.

If you use these scripts in any published reseaerch, cite [our paper](https://md.ekstrandom.net/pubs/book-author-gender):

> Michael D. Ekstrand, Mucun Tian, Mohammed R. Imran Kazi, Hoda Mehrpouyan, and Daniel Kluver. 2018. Exploring Author Gender in Book Rating and Recommendation. In *Proceedings of the 12th ACM Conference on Recommender Systems* (RecSys '18). ACM, pp. 242–250. DOI:[10.1145/3240323.3240373](https://doi.org/10.1145/3240323.3240373). arXiv:[1808.07586v1](https://arxiv.org/abs/1808.07586v1) [cs.IR].

**Note:** the limitations section of the paper contains important information about
the limitations of the data these scripts compile.  **Do not use this data or tools
without understanding those limitations**.  In particular, VIAF's gender information
is incomplete and, in a number of cases, incorrect.

We use [Data Version Control](https://dvc.org) (`dvc`) to script the import and wire
its various parts together.

## Requirements

- PostgreSQL 10 or later with [orafce](https://github.com/orafce/orafce) and `pg_prewarm` (from the
  PostgreSQL Contrib package) installed.
- Python 3.6 or later with the following packages:
    - psycopg2
    - numpy
    - tqdm
    - pandas
    - numba
    - colorama
    - chromalog
    - natural
    - dvc
- The Rust compiler (available from Anaconda)
- 2TB disk space for the database
- 100GB disk space for data files

It is best if you do not store the data files on the same disk as your PostgreSQL database.

The `environment.yml` file defines an Anaconda environment that contains all the required packages except for the PostgreSQL server. It can be set up with:

    conda create -f environment.yml

All scripts read database connection info from the standard PostgreSQL client environment variables:

- `PGDATABASE`
- `PGHOST`
- `PGUSER`
- `PGPASSWORD`

Alternatively, they will read from `DB_URL`.

## Initializing and Configuring the Database

After creating your database, initialize the extensions (as the database superuser):

    CREATE EXTENSION orafce;
    CREATE EXTENSION pg_prewarm;
    CREATE EXTENSION "uuid-ossp";

The default PostgreSQL performance configuration settings will probably not be
very effective; we recommend turning on parallelism and increasing work memory,
at a minimum.

## Downloading Data Files

This imports the following data sets:

-   Library of Congress MDSConnect Open MARC Records from <https://www.loc.gov/cds/products/MDSConnect-books_all.html>.
-   LoC MDSConnect Name Authorities from <https://www.loc.gov/cds/products/MDSConnect-name_authorities.html>.
-   Virtual Internet Authority File - get the MARC 21 XML data file from <http://viaf.org/viaf/data/>.
-   OpenLibrary Dump - the editions, works, and authors dumps from <https://openlibrary.org/developers/dumps>.
-   Amazon Ratings - get the 'ratings only' data for _Books_ from <http://jmcauley.ucsd.edu/data/amazon/> and save it in `data`.
-   BookCrossing - the BX-Book-Ratings CSV file from <http://www2.informatik.uni-freiburg.de/~cziegler/BX/>.

Several of these files can be auto-downloaded with the DVC scripts; others will need to be manually downloaded.

## Running Everything

You can run the entire import process with:

    dvc repro

Individual steps can be run with their corresponding `.dvc` files.

## Layout

The import code consists of Python, Rust, and SQL code, wired together with DVC.

### Python Scripts

Python scripts live under `scripts`, as a Python package.  They should not be launched directly, but
rather via `run.py`, which will make sure the environment is set up properly for them.

### DVC Usage and Stage Files

In order to allow DVC to be aware of current database state, we use a little bit of an unconventional
layout for many of our DVC scripts.  Many steps have two `.dvc` files with associated outputs:

-   `step.dvc` runs import stage `step`.
-   `step.transcript` is (consistent) output from running `step`, recording the actions taken.  It is
    registered with DVC as the output of `step.dvc`.
-   `step.status.dvc` is an *always-changed* DVC stage that depends on `step.transcript` and produces
    `step.status`, to check the current status in the database of that import stage.
-   `step.status` is an *uncached* output (so it isn't saved with DVC, and we also ignore it from Git)
    that is registered as the output of `step.status.dvc`.  It contains a stable status dump from the
    database, to check whether `step` is actually in the database or has changed in a meaningful way.

Steps that depend on `step` then depend on `step.status`, *not* `step.trasncript`.

The reason for this somewhat bizarre layoutis that if we just wrote the output files, and the database
was reloaded or corrupted, the DVC status-checking logic would not be ableto keep track of it.  This
double-file design allows us to make subsequent steps depend on the actual results of the import, not
our memory of the import in the Git repository.

The file `init.status` is an initial check for database initialization, and forces the creation of the
meta-structures used for tracking stage status.  Everything touching the database should depend on it,
directly or indirectly.
