% test script for air calibration

% clear;
% path
% addpath(genpath('../'));

% load recon xml
% reconxml = 'D:\matlab\data\simulation\recon_series1.xml';
reconxml = 'E:\data\rawdata\bhtest\recon_air.xml';
root = readcfgfile(reconxml);
if ~iscell(root.recon)
    root.recon = {root.recon};
end
% try 1st series
status.reconcfg = root.recon{1};
status.series_index = 1;

% initial
dataflow = struct();
prmflow = struct();
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'initial');

% load corr
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'loadcorrs');

% read raw data
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'loadrawdata');

% log2
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'log2');

% air calibration
[dataflow, prmflow, status] = nodesentry(dataflow, prmflow, status, 'Aircali');

% save to table (tmp hard code)
corrfile = 'E:\data\rawdata\bhtest\air_120KV300mA_large_v1.0.corr';
cfgfile = cfgmatchrule(corrfile, '');
corrcfg = readcfgfile(cfgfile);
packstruct(dataflow.aircorr, corrcfg, corrfile);

