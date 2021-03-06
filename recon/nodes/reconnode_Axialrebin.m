function [dataflow, prmflow, status] = reconnode_Axialrebin(dataflow, prmflow, status)
% recon node, Axial rebin 
% [dataflow, prmflow, status] = reconnode_Axialrebin(dataflow, prmflow, status);
% just put the reconnode_rebinprepare, reconnode_Azirebin and
% reconnode_Radialrebin in one function.
% Support QDO, (X)DFS and QDO+DFS

% % test DFS
% prmflow.recon.focalspot = [2 3];
% prmflow.recon.Nfocal = 2;

% rebin prepare
[prmflow, ~] = reconnode_rebinprepare(prmflow, status);

% Azi rebin
[dataflow, prmflow, ~] = reconnode_Azirebin(dataflow, prmflow, status);

% Radial rebin
[dataflow, prmflow, ~] = reconnode_Radialrebin(dataflow, prmflow, status);

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end