% function [dataflow, prmflow, status] = reconnode_crosstalkcali(dataflow, prmflow, status)
% crosstalk calibration
% [dataflow, prmflow, status] = reconnode_crosstalkcali(dataflow, prmflow, status)

% parameters to use in prmflow
Npixel = prmflow.recon.Npixel;
Nslice = prmflow.recon.Nslice;
Nps = Npixel*Nslice;
Nview = prmflow.recon.Nview;


% parameters to use
% caliprm = prmflow.pipe.(status.nodename);
caliprm = [];

% pixel number per module
if isfield(caliprm, 'Npixelpermod')
    Npixelpermod = caliprm.Npixelpermod;
elseif isfield(prmflow.system.detector, 'Npixelpermod')
    Npixelpermod = prmflow.system.detector.Npixelpermod;
else
    % default, 16 pixels in one module on x-direction
    Npixelpermod = 16;
end
% slice merge in expanding
if isfield(caliprm, 'Nmerge')
    Nmerge = caliprm.Nmerge;
else
    % defualt to merge 4 slices
    Nmerge = min(4, Nslice);
end

% format version of calibration table
if isfield(caliprm, 'corrversion')
    corrversion = caliprm.corrversion;
else
    corrversion = 'v1.0';
end

% inverse bh and nl
% find out the input data, I know they are rawdata_bk1, rawdata_bk2 ...
datafields = findfields(dataflow, '\<rawdata_bk');
Nbk = length(datafields);
headfields = findfields(dataflow, '\<rawhead_bk');

% in which odd are the original value, even are the ideal value (fitting target)
% reshape
for ibk = 1:Nbk
    dataflow.(datafields{ibk}) = reshape(dataflow.(datafields{ibk}), Nps, Nview);
end

% I know the air corr is in prmflow.corrtable
Aircorr = prmflow.corrtable.Air;
Aircorr.main = reshape(Aircorr.main, Nps, []);
% I know the beamharden corr is in prmflow.corrtable
BHcorr = prmflow.corrtable.Beamharden;
BHcorr.main = reshape(BHcorr.main, Nps, []);
% I know the nonlinear corr is in dataflow
NLcorr = dataflow.nonlinearcorr;
NLcorr.main = reshape(NLcorr.main, Nps, []);
% I know
HCscale = 1000;

% inverse the ideal data
for ibk = 2:2:Nbk
    % inverse Housefield
    dataflow.(datafields{ibk}) = dataflow.(datafields{ibk})./HCscale;
    for ipx = 1:Nps
        % inverse beamharden
        dataflow.(datafields{ibk})(ipx, :) = iterinvpolyval(BHcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
    end
    % inverse air (almost)
%     dataflow.(datafields{ibk}) = dataflow.(datafields{ibk}) + airrate;
end
% inverse the original data
for ibk = 1:2:Nbk
    % inverse Housefield
    dataflow.(datafields{ibk}) = dataflow.(datafields{ibk})./HCscale;
    for ipx = 1:Nps
        % apply the non-linear corr
        dataflow.(datafields{ibk})(ipx, :) = iterpolyval(NLcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
        % inverse beamharden
        dataflow.(datafields{ibk})(ipx, :) = iterinvpolyval(BHcorr.main(ipx, :), dataflow.(datafields{ibk})(ipx, :));
    end
    % inverse air (almost)
%     dataflow.(datafields{ibk}) = dataflow.(datafields{ibk}) + airrate;
end
% we should move above codes in another node specially do inverse

% to intensity
for ibk = 1:Nbk
    dataflow.(datafields{ibk}) = 2.^(-dataflow.(datafields{ibk}));
end
% 
% % matrix of diff
% D =spdiags(repmat([1 -1], Npixel, 1), [0, 1], Npixel, Npixel);
% 
% % ini 
% P = zeros(Npixel, Nslice);
% % loop the slices
% for islice = 1:Nslice
%     % echo '.'
%     fprintf('.');
%     % index to find the pixels and other
%     pixelindex = (1:Npixel) + (islice-1)*Npixel;
%     % get the data of cuurent slice
%     x = zeros(Npixel, Nview*Nbk/2);
%     y = zeros(Npixel, Nview*Nbk/2);
%     index_range = zeros(2, Nview*Nbk/2);
%     for ibk = 1:Nbk/2
%         ix = ibk*2-1;
%         iy = ibk*2;
%         viewindex = (1:Nview) + (ibk-1)*Nview;
%         x(:, viewindex) = double(dataflow.(datafields{ix})(pixelindex, :));
%         y(:, viewindex) = double(dataflow.(datafields{iy})(pixelindex, :));
%         ir = [1; 2] + (islice-1)*2;
%         index_range(:, viewindex) = dataflow.(headfields{ibk}).index_range(ir, :);
%     end
%     % effective data
%     Seff = zeros(Npixel, Nview*Nbk/2);
%     for iview = 1:Nview*Nbk/2
%         Seff(index_range(1, iview):index_range(2, iview), iview) = 1.0;
%     end
%     % smooth
%     alpha_smooth = 0.03;
%     x_sm = zeros(Npixel, Nview*Nbk/2);
%     y_sm = zeros(Npixel, Nview*Nbk/2);
%     for iview = 1:Nview*Nbk/2
%         x_sm(:, iview) = smooth(x(:,iview), alpha_smooth, 'loess');
%         y_sm(:, iview) = smooth(y(:,iview), alpha_smooth, 'loess');
%     end
%     % remnant to correct
%     Rxy = D\((y./y_sm-x./x_sm).*Seff);
%     % norm verctor and norm
%     Dx_sm = (D'*x_sm)./x_sm.*Seff;
%     nrDx_sm = sum(Dx_sm.^2, 2);
%     % P is cross talk coeffient
%     P(:, islice) = sum(Rxy.*Dx_sm, 2)./nrDx_sm;
%     % NOTE: suppose the cross talk correction is x = x + Ax, where A = D*diag(P)*D'.
%     
%     % skip the results too lack in effective view number
%     n_eff = squeeze(sum(reshape(Seff, Npixel, Nview, Nbk/2), 2));
%     pixel_eff = all(n_eff>Nview/2, 2);
%     P(~pixel_eff, islice) = nan;
% end
% 
% % copy
% Pcross = P;
% 
% % % smooth shift
% % smooth_alpha = Npixelpermod*3;
% % for islice = 1:Nslice
% %     Pcross(:, islice) = P(:, islice) - smooth(P(:, islice), smooth_alpha);
% % end
% 
% % merge and expand
% Nslice_mg = Nslice/Nmerge;
% Nmod = Npixel/Npixelpermod;
% for islice_mg = 1:Nslice_mg
%     % slice index
%     sliceindex = (1:Nmerge) + (islice_mg-1)*Nmerge;
%     % mean of Pcross on these slices
%     Pmerge = mean(Pcross(:, sliceindex), 2);
%     Pmerge = reshape(Pmerge, Npixelpermod, Nmod);
%     % find out the modules have nan
%     expandmod = any(isnan(Pmerge), 1);
%     Nexp = sum(expandmod);
%     % the pixels' index in these modules
%     expandindex = repmat(expandmod, Npixelpermod, 1);
%     % mean of the available P to a single module
%     Pmod = mean(Pmerge, 2, 'omitnan');
%     % replace the merged pixels
%     Pcross(:, sliceindex) = repmat(Pmerge(:), 1, Nmerge);
%     % replace the modules have nan in Pcross
%     Pcross(expandindex(:), sliceindex) = repmat(Pmod, Nexp, Nmerge);
%     % debug? replacea  all by Pmod
% %     Pcross(:, sliceindex) = repmat(Pmod, Nmod, Nmerge);
% end
% 
% % NOTE: as we defined the \delta X_i = X_i-X_{i-1}, therefor the P_i is the crosstalk coeffient between the pixel i and i-1.
% % The correction shall be like this X = X + D*diag(P)*D'*X, where D is the matrix we defined before,
% % D = spdiags(repmat([1 -1], Npixel, 1), [0, 1], Npixel, Npixel). A small numerical test will be helpful in writing a
% % correction code.
% 
% % set first pixel to 0
% Pcross(1, :) = 0;
% 
% % paramters for corr
% crosstalkcorr = caliprmforcorr(prmflow, corrversion);
% % copy results to corr
% crosstalkcorr.Nslice = Nslice;
% crosstalkcorr.order = 1;
% crosstalkcorr.mainsize = Nps;
% crosstalkcorr.main = Pcross;
% 
% % to return
% dataflow.crosstalkcorr = crosstalkcorr;
% 
% % status
% status.jobdone = true;
% status.errorcode = 0;
% status.errormsg = [];
% 
% end