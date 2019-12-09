function aircorr = simuAircali(SYS, Dataflow, Nsection)
% simulation of air calibration
% aircorr = simuAircali(SYS, Dataflow, Nsection)

if nargin < 3
    Nsection = 1;
end
Nw = SYS.source.Wnumber;
% Npixel
Npixel = SYS.detector.Npixel;
% Start_Slice
startslice = SYS.detector.startslice;
% End_Slice
endslice = SYS.detector.endslice;
% Slice_merge
slicemerge = SYS.detector.mergescale;
% Slice_Number
slicenumber = max(SYS.detector.slicemerge);
% focalspot
focalspot = SYS.protocol.focalspot;
focalspot = sum(2.^(focalspot-1));
% bowtie
bowtie = SYS.protocol.bowtie;

% I know the Dataflow.Pair is the air data
% corr table baseline
aircorr_basefile = [SYS.path.IOstandard, 'air_sample_v1.0.corr'];
if exist(aircorr_basefile, 'file')
    aircorr_base = loaddata(aircorr_basefile, SYS.path.IOstandard);
else
    % empty baseline
    aircorr_base = struct();
end
% initial
aircorr = cell(1, Nw);
aircorr(:) = {aircorr_base};
% loop Nw
for iw = 1:Nw
    % values to put in struct depending on KV mA
    KV = SYS.source.KV{iw};
    mA_air = SYS.source.mA_air{iw};
    % air main
    aircorr{iw}.ID = [0 0 1 0];
    aircorr{iw}.Npixel = Npixel;
    aircorr{iw}.Nslice = slicenumber;
    aircorr{iw}.startslice = startslice;
    aircorr{iw}.endslice = endslice;
    aircorr{iw}.slicemerge = slicemerge;
    aircorr{iw}.focalspot = focalspot;
    aircorr{iw}.mainsize = length(aircorr{iw}.main);
    aircorr{iw}.Nsection = Nsection;
    
    
    
    aircorr{iw}.KV = KV;
    aircorr{iw}.mA = mA_air;
    % reference
    aircorr{iw}.reference = ones(1, Nsection);
    % main
    aircorr{iw}.main = repmat(single(Dataflow.Pair{iw}(:)), 1, Nsection);
end

end