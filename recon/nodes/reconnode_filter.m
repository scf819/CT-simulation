function [dataflow, prmflow, status] = reconnode_Filter(dataflow, prmflow, status)
% recon node, filter design and conv
% [dataflow, prmflow, status] = reconnode_filter(dataflow, prmflow, status);

% filter
filter = prmflow.corrtable.(status.nodename);

% design filter
if isfield(filter, 'name')  || ifchar(filter)
    if isfield(filter, 'freqscale')
        freqscale = filter.freqscale;
    else
        freqscale = 1.0;
    end
    if ifchar(filter)
        filtname = filter;
    else
        filtname = filter.name;
    end
    H = filterdesign(filtname, prmflow.recon.Npixel, prmflow.recon.delta_d, freqscale);
elseif isfield(filter, 'file')
    if ~exist(filter.file, 'file')
        error('Can not find filter file: %s', filter.file);
    end
    fid = fopen(filter.file, 'r');
    H = fread(fid, inf, 'single');
    fclose(fid);
else
    error('Filter is not defined!');
end
prmflow.recon.filter = H;

% conv
% TBC

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end