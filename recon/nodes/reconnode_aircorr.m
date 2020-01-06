function [dataflow, prmflow, status] = reconnode_aircorr(dataflow, prmflow, status)
% recon node, air correction
% [dataflow, prmflow, status] = reconnode_aircorr(dataflow, prmflow, status);

% parameters to use in prmflow
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nview = prmflow.recon.Nview;
Nfocal = prmflow.system.Nfocal;
% parameters set in pipe
airprm = prmflow.pipe.(status.nodename);

% calibration table
aircorr = prmflow.corrtable.(status.nodename);
% parameters in corr
Nsect = single(aircorr.Nsection);
refpixel = aircorr.refpixel;
Nref = aircorr.refnumber;
if isfield(aircorr, 'referrcut')
    referrcut = reshape(aircorr.referrcut, Nref, Nfocal);
else
    referrcut = zeros(Nref, Nfocal);
end

% angles of the air table
sectangle = (pi*2/Nsect);
% airangle = (-1:Nsect).*(pi*2/Nsect);
% airmain & airref
aircorr.main = reshape(aircorr.main, [], Nsect);
airmain = [aircorr.main aircorr.main(:,1)];
if isfield(aircorr, 'referenceKVmA')
    airKVmA = rshape(aircorr.referenceKVmA, [], Nsect);
    airKVmA = [airKVmA airKVmA(:, 1)];
else
    airKVmA = zeros(Nfocal, Nsect+1);
end

% interpolation index and weight
retangle = mod(dataflow.rawhead.viewangle - aircorr.firstangle, pi*2);
intp_index = floor(retangle./sectangle);
intp_alpha = retangle./sectangle - intp_index;
intp_index = intp_index + 1;

% reshape
dataflow.rawdata = reshape(dataflow.rawdata, Npixel*Nslice, Nview);

% KVmA
KVmA = -log2(dataflow.rawhead.KV.*dataflow.rawhead.mA);

% corr rawdata with air
for ifocal = 1:Nfocal
    % rawdata
    viewindex = ifocal:Nfocal:Nview;
    airindex = (1:Npixel*Nslice) + Npixel*Nslice*(ifocal-1);
    dataflow.rawdata(:, viewindex) = dataflow.rawdata(:, viewindex) - airmain(airindex, intp_index).*(1-intp_alpha(viewindex));
    dataflow.rawdata(:, viewindex) = dataflow.rawdata(:, viewindex) - airmain(airindex, intp_index+1).*intp_alpha(viewindex);
    % KVmA
    KVmA(viewindex) = KVmA(viewindex) - airKVmA(ifocal, intp_index).*(1-intp_alpha(viewindex));
    KVmA(viewindex) = KVmA(viewindex) - airKVmA(ifocal, intp_index+1).*intp_alpha(viewindex);
end

% rawref
[rawref, referr] = airreference2(dataflow.rawdata, refpixel, Npixel, Nslice);



% corr rawdata with ref
for ifocal = 1:Nfocal
    viewindex = ifocal:Nfocal:Nview;
    refindex = (1:Nref) + Nref*(ifocal-1);
    dataflow.rawdata(:, viewindex) = dataflow.rawdata(:, viewindex) - mean(rawref(refindex, :), 1);
end
% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end

function referenceblock(rawref, referr, airprm)
% reference block

block_cut = 4.0e-4;
m_blk = 10;
blk1 = conv(referr(1,:)>block_cut, ones(1, 2*m_blk+1));
blk2 = conv(referr(2,:)>block_cut, ones(1, 2*m_blk+1));
blk1 = blk1(m_blk+1:end-m_blk)>0;
blk2 = blk2(m_blk+1:end-m_blk)>0;

idx_both = ~blk1 & ~blk2;

ref = zeros(1, Nview);
ref(idx_both) = (ref1(idx_both) + ref2(idx_both))./2;

if any(~idx_both)
    % some views are blocked
    blkidx_1 = ~blk1 & blk2;
    blkidx_2 = blk1 & ~blk2;
    %
    view_bkl1 = find(~idx_both, 1, 'first');
    view0 = find(idx_both, 1, 'first');
    if view_bkl1==1
        %1 go back
        for ii = view0-1:-1:1
            if blkidx_1(ii)
                % ref1
                ref(ii) = ref(ii+1)-ref1(ii+1)+ref1(ii);
            elseif blkidx_2(ii)
                % ref2
                ref(ii) = ref(ii+1)-ref2(ii+1)+ref2(ii);
            else
                % mA
                1;
            end
        end
        %2 forward
        view_bkl1 = find(~idx_both(view0:end), 1, 'first');
    end
    for ii = view_bkl1:Nview
        if idx_both(ii)
            continue
        end
        if blkidx_1(ii)
            % ref1
            ref(ii) = ref(ii-1)-ref1(ii-1)+ref1(ii);
        elseif blkidx_2(ii)
            % ref2
            ref(ii) = ref(ii-1)-ref2(ii-1)+ref2(ii);
        else
            % mA
            1;
        end
        
        
    end
end