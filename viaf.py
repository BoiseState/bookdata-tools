import logging
from invoke import task

import support as s

_log = logging.getLogger(__name__)


@task(s.init, s.build, name='import')
def import_viaf(c, date='20181104', force=False):
    "Import VIAF data"
    s.start('viaf-import', force=force)
    _log.info('initializing VIAF schema')
    s.psql(c, 'viaf-schema.sql', True)
    infile = s.data_dir / f'viaf-{date}-clusters-marc21.xml.gz'
    _log.info('importing VIAF data from %s', infile)

    s.pipeline([
        [s.bin_dir / 'parse-marc', '--db-schema', 'viaf', '-t', 'marc_field', '--line-mode', infile]
    ])
    s.finish('viaf-import')

@task(s.init)
def index(c, force=False):
    "Index VIAF data"
    s.check_prereq('viaf-import')
    s.start('viaf-index', force=force)
    _log.info('building VIAF indexes')
    s.psql(c, 'viaf-index.sql', True)
    s.finish('viaf-index')
