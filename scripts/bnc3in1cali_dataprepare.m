
% step0.1 dataprepare for BH calibration
toloop = struct();
toloop.focalsize = {'small', 'large'};
toloop.collimator = [];
toloop.KV = [80 100 120 140];

filepath = struct();
filepath.empty.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582870883044.0_AIR';
filepath.empty.namekey = 'empty';
filepath.body.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582870883044.0_AIR';
filepath.body.namekey = 'body';
filepath.head.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582870883044.0_AIR';
filepath.head.namekey = 'head';

% fileext
fileext = '.pd';

% get file names
datafile_bh = calidataprepare(toloop, filepath, fileext);

% step0.2 dataprepare for nonliear/crosstalk calibration

toloop = struct();
toloop.bowtie = {'body', 'head'};
toloop.focalsize = {'small', 'large'};
toloop.KV = [80 100 120 140];

filepath = struct();
filepath.air.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582870883044.0_AIR';
filepath.air.namekey = '';
filepath.water200c.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582884571221.0_WATER22_ISO';
filepath.water200c.namekey = '';
filepath.water200off.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582876134042.0_WATER22_9CM';
filepath.water200off.namekey = '';
filepath.water300c.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582883779173.0_WATER32_ISO';
filepath.water300c.namekey = '';
filepath.water300off.path = 'F:\data-Dier.Z\PG\bay3\DATA\1.1582877389092.0_WATER32_9CM';
filepath.water300off.namekey = '';

% fileext
fileext = '.pd';

% get file names
datafile_nl = calidataprepare(toloop, filepath, fileext);


