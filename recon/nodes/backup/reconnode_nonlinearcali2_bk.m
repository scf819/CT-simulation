function [dataflow, prmflow, status] = reconnode_nonlinearcali(dataflow, prmflow, status)
% nonlinear calibration
% [dataflow, prmflow, status] = reconnode_nonlinearcali(dataflow, prmflow, status)

% parameters to use in prmflow
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nps = Npixel*Nslice;
Nview = prmflow.recon.Nview;

% parameters to use
if ~isempty(status)
    caliprm = prmflow.pipe.(status.nodename);
else
    % for debug
    caliprm = struct();     
end

% polynomial order
if isfield(caliprm, 'polyorder')
    n_poly = caliprm.polyorder;
else
    % order of nonlinear poly, default is 2
    n_poly = 2;
    % NOTE: large order could be unstable
end
% fit weighting
if isfield(caliprm, 'weight')
    fit_weight = caliprm.weight(:);
else
    fit_weight = [];
end
% HCscale
if isfield(caliprm, 'HCscale')
    HCscale = caliprm.HCscale;
else
    HCscale = 1000;
end
% format version of calibration table
if isfield(caliprm, 'corrversion')
    corrversion = caliprm.corrversion;
else
    corrversion = 'v1.0';
end
% echo .
echo_onoff = true;

% I know the input data are rawdata_bk1, rawdata_bk2 ...
% find out them
datafields = findfields(dataflow, '\<rawdata_bk');
Nbk = length(datafields);
% I know Nbk must be even
% and the rawhead
headfields = findfields(dataflow, '\<rawhead_bk');

% reshape
for ibk = 1:Nbk
    dataflow.(datafields{ibk}) = reshape(dataflow.(datafields{ibk}), Nps, Nview);
end

% index range
index_range = zeros(2, Nslice, Nview, Nbk/2);
for ibk = 1:Nbk/2
    index_range(:,:,:, ibk) = reshape(dataflow.(headfields{ibk}).index_range, 2, Nslice, Nview);
end

% ini the coefficients of the polynomal
poly_nonl = nan(Npixel, Nslice, n_poly);
% initial value of the fitting
t0 = zeros(1, n_poly);
t0(n_poly) = 1.0;

weight = ones(Nbk/2, 1);
% input weight?
if ~isempty(fit_weight)
    if length(fit_weight)>=Nbk/2
        weight = fit_weight(1:Nbk/2);
    else
        weight(1:length(fit_weight)) = fit_weight;
    end
end
w = repmat(weight, 1, Nview);

% view number cuts & transition sections
viewcut1 = Nview/4;
viewcut2 = Nview/8;
mintrans = 4;

% loop the pixels to fit the polynomal for each
for islice = 1:Nslice
    if echo_onoff, fprintf('.'); end
    % index range
    Srange = zeros(Npixel, Nview, Nbk/2);
    for ibk = 1:Nbk/2
        for iview = 1:Nview
            Srange(index_range(1, islice, iview, ibk) : index_range(2, islice, iview, ibk), iview, ibk) = 1;
        end
    end
    % check a available views
    savail1 = squeeze(sum(Srange, 2)>=viewcut1);
    savail2 = squeeze(sum(Srange, 2)>=viewcut2);
    % I know there will be Nbk/2 steps
    % ini
    p = zeros(Npixel, n_poly, Nbk/2);
%     p(:, n_poly, :) = 1.0;
    step_set = false(Nbk/2, Nbk/2);
    for ibk = 1:Nbk/2
        i_avail = find(sum(savail1, 2)>=ibk, 1, 'first');
        step_set(:, ibk) = savail1(i_avail, :)';
    end
    
    % For each slice we will start from the middle pixel that will be more stable though a little troublesome.
    midu = floor(Npixel/2);
    % ini the initial value for ipixel
    t0_ipx = repmat(t0, Nbk/2, 1);
    % loop from midu+1 to end, then from midu to 1
    loopindex = [(midu+1:Npixel) (midu:-1:1)];
    for ii = 1:Npixel
        index = loopindex(ii);
        % reset t0 when restart from midu
        if index == midu
            t0_ipx = repmat(t0, Nbk/2, 1);
        end
        % pixel index
        ipixel = index+(islice-1)*Npixel;
        % set the data to fit
        [x, y, s] = getdatatofit(dataflow, datafields, index, ipixel, Nbk, Nview, HCscale, Srange);
        
        Nstep = sum(savail2(index, :));
        for istep = 1:Nstep
            % start from 1st step
            s_is = s & step_set(:, istep);
            p(index, :, istep) = calipolyfit(x(s_is), y(s_is), w(s_is), t0_ipx(istep, :));
            t0_ipx(istep, :) = p(index, :, istep);
        end
    end
    % link the p 
    p = linkpsteps(p, Nbk/2, savail1, savail2, mintrans);
    % copy to poly_nonl
    index_avail = sum(savail2, 2) >= 1;
    poly_nonl(index_avail, islice, :) = p(index_avail, :, end);
end
% fillup nan
poly_nonl = reshape(fillmissing(reshape(poly_nonl, Npixel, []), 'nearest'), [], n_poly);

% % debug
% poly_nonl = reshape(poly_nonl, Npixel, Nslice, n_poly);
% poly_nonl(1:214,:,1) = 0;
% poly_nonl(1:214,:,2) = 1;
% poly_nonl(642:end,:,1) = 0;
% poly_nonl(642:end,:,2) = 1;
% poly_nonl = reshape(poly_nonl, [], n_poly);

% mix with provious nonlinear table
if isfield(prmflow.corrtable, 'Nonlinear')
    poly_prv = reshape(prmflow.corrtable.Nonlinear.main, Nps, []);
    n_poly_prv = size(poly_prv, 2);
    % merge
    poly_merge = mergeiterpoly3to5(poly_prv, poly_nonl);
    % new poly
    n_poly = min( max(n_poly, n_poly_prv)+1, 5);
    poly_nonl = poly_merge(:, end-n_poly+1:end);
end

% paramters for corr
nonlinearcorr = caliprmforcorr(prmflow, corrversion);
% copy results to corr
nonlinearcorr.Nslice = Nslice;
nonlinearcorr.order = n_poly;
nonlinearcorr.mainsize = Nps*n_poly;
nonlinearcorr.main = poly_nonl;

% to return
dataflow.nonlinearcorr = nonlinearcorr;

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end


function [x, y, s] = getdatatofit(dataflow, datafields, index, ipixel, Nbk, Nview, HCscale, Srange)
% get the data to fit

x = zeros(Nbk/2, Nview);
y = zeros(Nbk/2, Nview);

for ibk = 1:Nbk/2
    % x is the original data in fitting
    ix = ibk*2-1;   % 1 3 5 7
    x(ibk, :) = double(dataflow.(datafields{ix})(ipixel, :)) ./ HCscale;
    % y is the target data
    iy = ibk*2;     % 2 4 6 8
    y(ibk, :) = double(dataflow.(datafields{iy})(ipixel, :)) ./ HCscale;
    % cut y by index range
    y(ibk, :) = y(ibk, :).*Srange(index, :, ibk);
end
% available data
s = y>0;

end


function p = calipolyfit(x, y, w, t0)
% fit f(x) to y by looking for a polynomial f: min(||(x-f^{-1}(y)).*w||)

options = optimoptions('lsqnonlin','Display','off');
% the algorithm is reverse generator base on lsqnonlin
p = lsqnonlin(@(t) (iterinvpolyval(t, y)-x).*w, t0, [], [], options);
if p(1)>0.5
    % unstable? redo the fitting start with [0, 1]
    t0 = zeros(size(t0));
    t0(end) = 1;
    p = lsqnonlin(@(t) (iterinvpolyval(t, y)-x).*w, t0, [], [], options);
end
end


function p = linkpsteps(p, Nstep, savail1, savail2, mintrans)

for istep = Nstep-1:-1:1
    % right part
    index2 = find(sum(savail2, 2)>=istep+1, 1, 'last');
    index1 = min(find(sum(savail1, 2)>=istep+1, 1, 'last'), index2-mintrans);
    m12 = index2-index1;
    intp12 = (0:m12)'./m12;
    index_end = find(sum(savail2, 2)>=istep, 1, 'last');
    mean_up = mean(p(index1:index2, :, end));
    mean_low = mean(p(index1:index2, :, istep));
    p_fix = p(index1:index_end, :, istep) + mean_up - mean_low;
    p_fix(1:m12+1,:) = p_fix(1:m12+1,:).*intp12;
    p(index1:index2, :, end) = p(index1:index2, :, end).*(1-intp12);
    p(index1:index_end, :, end) = p(index1:index_end, :, end) + p_fix;
    % left part
    index2 = find(sum(savail2, 2)>=istep+1, 1, 'first');
    index1 = max(find(sum(savail1, 2)>=istep+1, 1, 'first'), index2+mintrans);
    m12 = index1-index2;
    intp12 = (m12:-1:0)'./m12;
    index_end = find(sum(savail2, 2)>=istep, 1, 'first');
    mean_up = mean(p(index2:index1, :, end));
    mean_low = mean(p(index2:index1, :, istep));
    p_fix = p(index_end:index1, :, istep) + mean_up - mean_low;
    p_fix(end-m12:end,:) = p_fix(end-m12:end,:).*intp12;
    p(index2:index1, :, end) = p(index2:index1, :, end).*(1-intp12);
    p(index_end:index1, :, end) = p(index_end:index1, :, end) + p_fix;
end
    
end

function r = mergeiterpoly3to5(a, b)
% to merge two polymal only for <=3 order and only output order 1-5 

[n, Na] = size(a);
Nb = size(b, 2);

if Na>3
    a = a(:, end-2:end);
elseif Na<3
    tmp = a;
    a = zeros(n, 3);
    a(:,end-Na+1:end) = tmp;
end

if Nb>3
    b = b(:,end-2:end);
elseif Nb<3
    tmp = b;
    b = zeros(n, 3);
    b(:, end-Nb+1:end) = tmp;
end

% I know
% f(r, x) = b1*b2*b3*a1^3*a2^3*a3^3*x^9 + 3*b1*b2*b3*a1^2*a2^3*a3^3*x^8 + 3*b1*b2*b3*a1^2*a2^2*a3^3*x^7 + 
%           b2*b3*a1^2*a2^2*a3^2*x^6 + 3*b1*b2*b3*a1*a2^3*a3^3*x^7 + 6*b1*b2*b3*a1*a2^2*a3^3*x^6 + 2*b2*b3*a1*a2^2*a3^2*x^5 + 
%           3*b1*b2*b3*a1*a2*a3^3*x^5 + 2*b2*b3*a1*a2*a3^2*x^4 + b3*a1*a2*a3*x^3 + b1*b2*b3*a2^3*a3^3*x^6 + 
%           3*b1*b2*b3*a2^2*a3^3*x^5 + b2*b3*a2^2*a3^2*x^4 + 3*b1*b2*b3*a2*a3^3*x^4 + 2*b2*b3*a2*a3^2*x^3 + b3*a2*a3*x^2 + 
%           b1*b2*b3*a3^3*x^3 + b2*b3*a3^2*x^2 + b3*a3*x

m = 5;
r = zeros(n , m);
% 1
r(:, m) = a(:,3).*b(:,3);
% 2
c2 = b(:,2).*a(:,3) + a(:,2);
r(:, m-1) = c2;
% 3
c3 = b(:,1).*b(:,2).*a(:,3).^2 + 2.*b(:,2).*a(:,2).*a(:,3) + a(:,1).*a(:,2);
r(:, m-2) = c3./c2;
% 4
c4 = a(:,2).*a(:,3).*b(:,2).*(2.*a(:,1) + a(:,2) + 3.*a(:,3).*b(:,1));
r(:, m-3) = c4./c3;
% 5
c5 = a(:,2).*a(:,3).*b(:,2).*(2.*a(:,1).*a(:,2) + 3.*a(:,1).*a(:,3).*b(:,1) + 3.*a(:,2).*a(:,3).*b(:,1));
r(:, m-4) = c5./c4;

% skip nan
r(~isfinite(r)) = 0;
s = [abs(r(:,1:m-1))>0.5 false(n, 1)];
r(s) = 0;

end
