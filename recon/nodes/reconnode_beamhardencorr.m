function [dataflow, prmflow, status] = reconnode_beamhardencorr(dataflow, prmflow, status)
% recon node, beamharden correction
% [dataflow, prmflow, status] = reconnode_beamhardencorr(dataflow, prmflow, status);

% parameters to use in prmflow
Nview = prmflow.recon.Nview;

% calibration table
bhcorr = prmflow.corrtable.(status.nodename);
bhorder = bhcorr.order;
bhpoly = reshape(bhcorr.main, [], bhorder);

% beam harden polynomial
dataflow.rawdata = reshape(dataflow.rawdata, [], Nview);
dataflow.rawdata = iterpolyval(bhpoly, dataflow.rawdata);

%--- test ---%
% nonlinear
corr_p = load('E:\data\rawdata\bhtest\p_n3.mat');
p = corr_p.p;
dataflow.rawdata = reshape(dataflow.rawdata, size(p,1), []);
dataflow.rawdata = iterpolyval(p, dataflow.rawdata);
%--- test over ---%

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end