% function Dataflow = projectionscan(SYS, method, echo_onoff)
% the projection simulation

method = 'energyvector';
echo_onoff = true;

% ini GPU Device
gpuD = gpuDevice;

tic;

% system components
source = SYS.source;
bowtie = SYS.collimation.bowtie;
filter = SYS.collimation.filter;
detector = SYS.detector;
if isfield(SYS, 'phantom')
    phantom = SYS.phantom;
else
    phantom = [];
end

% parameters of the system
focalposition = source.focalposition;
Nfocal = source.focalnumber;
Npixel = double(detector.Npixel);
Nslice = double(detector.Nslice);
Np = Npixel * Nslice;
Nw = source.Wnumber;
Mlimit = SYS.simulation.memorylimit;

% prepare the samplekeV, viewangle and couch
[samplekeV, viewangle, couch, shotindex, gantrytilt] = scanprepare(SYS);
Nsample = length(samplekeV(:));
Nview = length(viewangle(:));
Nviewpf = Nview/Nfocal;

% spectrums normalize
sourcespect = SYS.source.spectrum;
for ii = 1:Nw
    sourcespect{ii} = sourcespect{ii}./sum(sourcespect{ii}.*samplekeV);
end
% detector response
detspect = cell(1, Nw);
respnorm = sum(samplekeV)/mean(detector.response * samplekeV(:), 1);
for ii = 1:Nw
    detspect{ii} = detector.response.*sourcespect{ii}.*respnorm;
    if size(detspect{ii}, 1) == 1
        detspect{ii} = repmat(detspect{ii}, Np*Nfocal, 1);
    else
        detspect{ii} = repmat(detspect{ii}, Nfocal, 1);
    end
end

% memory limit
% maxview = floor(Mlimit*2^27/(Np*Nsample*Nfocal)) * Nfocal;
% maxview = 1;
% Nlimit = ceil(Nview/maxview);

% ini P & Eeff
P = cell(1, Nw);
Eeff = cell(1, Nw);
switch lower(method)
    case {'default', 1, 'photoncount', 2}
        P(:) = {zeros(Np, Nview)};
        Eeff(:) = {zeros(Np, Nview)};
    case {'energyvector', 3}
        P(:) = {zeros(Np*Nview, Nsample)};
        % No Eeff
    otherwise
        % error
        error(['Unknown projection method: ' method]);
end
Pair = cell(1, Nw);

% projection on bowtie and filter in collimation
[Dmu_air, L] = flewoverbowtie(focalposition, detector.position, bowtie, filter, samplekeV);
% distance curse
distscale = detector.pixelarea(:)./(L.^2.*(pi*4));
% energy based Posibility of air
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            Pair{ii} = (exp(-Dmu_air).*detspect{ii}) * samplekeV';
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'photoncount', 2}
            % photon counting
            Pair{ii} = sum(exp(-Dmu_air).*detspect{ii}, 2);
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'energyvector', 3}
            % maintain the components on energy
            Pair{ii} = exp(-Dmu_air).*detspect{ii};
            Pair{ii} = Pair{ii}.*distscale(:);
        otherwise
            % error
            error(['Unknown projection method: ' method]);
    end
    Pair{ii}(isnan(Pair{ii})) = 0;
end
toc;

% % projection on objects
tic;
[D, mu] = projectinphantom(focalposition, detector.position, phantom, samplekeV, viewangle, couch, gantrytilt, 1);
toc;

tic;
D = reshape(D, Np*Nfocal, Nviewpf, []);
% D = gpuArray(D);
% D = gpuArray(single(reshape(D, Np, Nview, [])));
mu = gpuArray(single(mu));
samplekeV_GPU = gpuArray(single(samplekeV));
detspect = cellfun(@(x) gpuArray(single(x)), detspect, 'UniformOutput', false);
% Nlimit = gpuArray(single(Nlimit));
Np = gpuArray(single(Np));
Nfocal = gpuArray(single(Nfocal));
distscale = gpuArray(single(distscale));
maxview = gpuArray(single(maxview));

Dmu_air = gpuArray(Dmu_air);
Dmu = gpuArray(zeros(size(Dmu_air)));
% for i_lim = 1:Nlimit
for iview = 1:Nviewpf
    % echo '.'
%     if echo_onoff, fprintf('.'); end
%     % view number for each step
%     if i_lim < Nlimit
%         Nview_lim = maxview;
%     else
%         Nview_lim = Nview - maxview*(Nlimit-1);
%     end
%     % index of view angles 
%     index_lim = (1:Nview_lim) + maxview*(i_lim-1);
%     index_D = (1:Np)' + (index_lim-1).*Np;
    
    % viewindex
    viewindex = (iview-1)*Nfocal + (1:Nfocal);

    % projection on objects    
    if ~isempty(D)
        Dmu = Dmu_air + gpuArray(squeeze(D(:, iview, :)))*mu;
%         Pmu = Dmu0 + squeeze(D(:, iview, :))*mu;
    else
        Dmu = Dmu_air;
    end
       
    % energy based Posibility
    for ii = 1:Nw
        switch lower(method)
            case {'default', 1}
                % ernergy integration
                Dmu = exp(-Dmu).*detspect{ii};
                % for quanmtum noise
                Eeff{ii}(:, viewindex) = gather(reshape(sqrt((Dmu * (samplekeV'.^2))./sum(Dmu, 2)), Np, Nfocal));
                % Pmu = integrol of Dmu 
                Pmu =  Dmu * samplekeV';
%                 Pmu = reshape(Pmu, Np*Nfocal, Nview_lim/Nfocal).*distscale(:);
                Pmu = Pmu(:).*distscale(:);
                P{ii}(:, viewindex) = gather(reshape(Pmu, Np, Nfocal));
%                 P{ii}(:, index_lim) = gather(reshape(reshape(Pmu*samplekeV', Np*Nfocal, Nview_lim/Nfocal).*distscale(:), Np, Nview_lim));
            case {'photoncount', 2}
                % photon counting
                Dmu = exp(-Dmu).*detspect{ii};
                Pmu = sum(Dmu, 2).*distscale(:);
                P{ii}(:, viewindex) = gather(reshape(Pmu, Np, Nfocal));
            case {'energyvector', 3}
                % maintain the components on energy
                Dmu = exp(-Dmu).*detspect{ii};
                Dmu = reshape(Dmu, Np*Nfocal, []).*distscale(:);
                index_p = (1:Np*Nfocal) + Np*Nfocal*(iview-1);
                P{ii}(index_p, :) = gather(reshape(Dmu, Np*Nfocal, []));
            otherwise
                % error
                error(['Unknown projection method: ' method]);
        end
    end
end
toc;

% remove nan (could due to negative filter thickness)
for ii = 1:Nw
    P{ii}(isnan(P{ii})) = 0;
end

% return
Dataflow = struct();
Dataflow.samplekeV = samplekeV;
Dataflow.viewangle = viewangle;
Dataflow.couch = couch;
Dataflow.shotindex = shotindex;
Dataflow.P = P;
Dataflow.Eeff = Eeff;
Dataflow.Pair = Pair;

% end
