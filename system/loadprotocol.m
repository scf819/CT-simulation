function SYS = loadprotocol(SYS)
% load the protocol (of current series) to system

% protocol
protocol = SYS.protocol;
% I know the protocol is configure.protocol.series{ii}

% initial
1;

% tube
% focal position
focalposition = reshape(SYS.source.tube_corr.focalposition, [], 3);
if isfield(SYS.source.tube_corr, 'focaldistort')
    fdis = SYS.source.tube_corr.focaldistort; 
    if length(fdis(:)) <= 1
        focalposition(1) = focalposition(1) + fdis;
    else
        fdis = reshape(fdis, [], 3);
        if size(focalposition, 1) == 1
            focalposition = repmat(focalposition, size(fdis,1), 1);
        end
        focalposition = focalposition + fdis;
    end
end
SYS.source.focalposition = focalposition(protocol.focalspot, :);
SYS.source.focalnumber = size(SYS.source.focalposition, 1);
% focal size
focalsize = reshape(SYS.source.tube_corr.focalsize, [], 2);
SYS.source.focalsize = focalsize(protocol.focalsize, :);
% KV mA (multi)
N_KV = length(protocol.KV);
N_mA = length(protocol.mA);
N_mAair = length(protocol.mA_air);
SYS.source.Wnumber = max(N_KV, N_mA);
if N_KV>1
    SYS.source.KV = num2cell(protocol.KV);
else
    SYS.source.KV = cell(SYS.source.Wnumber, 1);
    SYS.source.KV(:) = {protocol.KV};
end
if N_mA>1
    SYS.source.mA = num2cell(protocol.mA);
else
    SYS.source.mA = cell(SYS.source.Wnumber, 1);
    SYS.source.mA(:) = {protocol.mA};
end
if N_mAair>1
    SYS.source.mA_air = num2cell(protocol.mA_air);
else
    SYS.source.mA_air = cell(SYS.source.Wnumber, 1);
    SYS.source.mA_air(:) = {protocol.mA_air};
end
% spectrum
SYS.source.spectrum = cell(SYS.source.Wnumber, 1);
tube_corr = SYS.source.tube_corr;
tube_corr.main = reshape(tube_corr.main, [], tube_corr.KVnumber);
if strcmpi(SYS.simulation.spectrum, 'Single')
    samplekeV = SYS.world.refrencekeV;
else
    samplekeV = SYS.world.samplekeV;
end
for ii = 1:SYS.source.Wnumber
    KV_ii = SYS.source.KV{ii};
    spectdata = reshape(tube_corr.main(:, (tube_corr.KVtag == KV_ii)), [], 2);
    SYS.source.spectrum{ii} = interp1(spectdata(:,1), spectdata(:,2), samplekeV);
    SYS.source.spectrum{ii}(isnan(SYS.source.spectrum{ii})) = 0;
end

% collimation
% bowtie
% I know the bowtie index is
switch lower(protocol.bowtie)
    case {'empty', 0}
        % do nothing
        bowtie_index = [];
    case {'body', 'large', 1}
        bowtie_index = [1 2];
    case {'head', 'small', 2}
        bowtie_index = [3 4];
    otherwise
        error(['Unknown bowtie: ' protocol.bowtie]);
end
% loop multi-bowtie
for ii = 1:length(SYS.collimation.bowtie(:))
    % bowtie curve
    SYS.collimation.bowtie{ii} = ...
        getbowtiecurve(SYS.collimation.bowtie{ii}, SYS.source, bowtie_index);
    % bowtie material
    SYS.collimation.bowtie{ii}.material = SYS.collimation.bowtie{ii}.bowtie_corr.material;
end

% detector
% collimator -> detector 
SYS.detector = collimatorexposure(protocol.collimator, SYS.detector, SYS.detector.detector_corr);
% extra detector info (TBC)
% tmp hardcodes
SYS.detector.spectresponse = ones(size(samplekeV));
SYS.detector.pixelarea = 1.0;

% DCB
SYS.datacollector.integrationtime = protocol.integrationtime;

% output
% output file names
SYS.output.files = outputfilenames(SYS.output, protocol, SYS.source);

end


function bowtie = getbowtiecurve(bowtie, source, bowtie_index)
% get bowtie curve

if nargin < 3
    bowtie_index = [];
end

if isempty(bowtie_index)
    % empty bowtie
    bowtie.anglesample = [];
    bowtie.bowtiecurve = [];
    return
end

% original focal position
focal_orig = source.tube_corr.focalposition(1,:);
% bowtie_corr
bowtie_corr = bowtie.bowtie_corr;
% use bowtie_index to select bowtie
bowtie_corr.main = reshape(bowtie_corr.main, bowtie_corr.Nsample, []);
bowtiecv_orig = bowtie_corr.main(:, bowtie_index);
% I know the axis-x is from 0 to bowtie_corr.box(1)
bowtiecv_orig(:, 1) = bowtiecv_orig(:, 1) - bowtie_corr.box(1)/2;
% initial the returns
bowtie.bowtiecurve = zeros(bowtie_corr.Nsample, source.focalnumber);
bowtie.anglesample = zeros(bowtie_corr.Nsample, source.focalnumber);
% to loop the focal spots
for i_focal = 1:source.focalnumber
    focaltobottom = bowtie_corr.focaltobottom + ...
        focal_orig(1)- source.focalposition(i_focal, 1);
    bowtie.anglesample(:, i_focal) = atan2(focaltobottom - bowtiecv_orig(:, 2), ...
        bowtiecv_orig(:, 1) - source.focalposition(i_focal, 1)) - pi/2;
    bowtie.bowtiecurve(:, i_focal) = bowtiecv_orig(:, 2).*sec(bowtie.anglesample(:, i_focal));
end
% negative
% I know
sign_bowtiebox = sign(bowtie_corr.box(3));
% which should be sign(det(diag(bowtie_corr.box))), anyhow;
bowtie.bowtiecurve = bowtie.bowtiecurve.*sign_bowtiebox;

end


function files = outputfilenames(output, protocol, source)

files = struct();
% namekey
namekey = output.namekey;
if ~isempty(namekey)
    namekey = ['_' namekey];
end

% ini
Nw = source.Wnumber;
files.rawdata = cell(1, Nw);
files.aircorr = cell(1, Nw);

% switch name rule
switch lower(output.namerule)
    case {'default'}
        % default name rule
        for iw = 1:Nw
            % rawdata
            rawtags = ['_series' num2str(protocol.series_index) '_' ...
                protocol.scan '_' protocol.bowtie '_' protocol.collimator ...
                '_' num2str(source.KV{iw}) 'KV' num2str(source.mA{iw}) 'mA' '_' ...
                num2str(protocol.rotationspeed) 'secprot'];
            files.rawdata{iw} = ['rawdata' namekey rawtags];
            % air
            if strfind(output.corrtable, 'air')
                airtags = ['_series' num2str(protocol.series_index) '_' ...
                    protocol.scan '_' protocol.bowtie '_' protocol.collimator ...
                    '_' num2str(source.KV{iw}) 'KV' num2str(source.mA{iw}) 'mA' '_' ...
                    num2str(protocol.rotationspeed) 'secprot'];
                files.aircorr{iw} = ['air' airtags];
            end
            % offset
            % TBC
        end
    otherwise
        % most simple filenames
        for iw = 1:Nw
            rawtags = ['_series' num2str(protocol.series_index) '_' num2str(source.KV{iw}) 'KV'];
            files.rawdata{iw} = ['rawdata' namekey rawtags];
            % air
            if strfind(output.corrtable, 'air')
                files.aircorr{iw} = ['air' rawtags];
            end
            % offset
            % TBC
        end
end
% NOTE: those names without version tag, e.g. _v1.0, and EXT, .e.g. .raw.
end