function Dataflow = projectionscan(SYS, method)
% the projection simulation

if nargin<2
    method = 'default';
end

% system components
source = SYS.source;
bowtie = SYS.collimation.bowtie;
filter = SYS.collimation.filter;
detector = SYS.detector;
phantom = SYS.phantom;

% parameters of the system
focalposition = source.focalposition;
Nfocal = source.focalnumber;
Npixel = detector.Npixel;
Nslice = detector.Nslice;
Np = Npixel * Nslice;
Nw = SYS.source.Wnumber;

% prepare the samplekeV, viewangle and couch
[samplekeV, viewangle, couch, shotindex] = scanprepare(SYS);
Nsample = length(samplekeV(:));
Nview = length(viewangle(:));

% spectrums normalize
sourcespect = SYS.source.spectrum;
for ii = 1:Nw
    sourcespect{ii} = sourcespect{ii}./sum(sourcespect{ii}.*samplekeV);
end
% detector response
detspect = cell(1, Nw);
for ii = 1:Nw
    detspect{ii} = sourcespect{ii}.*detector.spectresponse;
end
% NOTE: noly one reponse curve supported yet

% ini Dmu, P
Dmu = zeros(Np*Nview, Nsample);
P = cell(1, Nw);
Pair = cell(1, Nw);

% projection on bowtie and filter in collimation
[Dmu_bowtie, L] = flewoverbowtie(focalposition, detector.position, bowtie, filter, samplekeV);
Dmu = Dmu + repmat(Dmu_bowtie, Nview/Nfocal, 1);

% distance curse
distscale = detector.pixelarea./(L.^2.*(pi*4));

% energy based Posibility of air
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            Pair{ii} = (exp(-Dmu(1:Np*Nfocal, :)).*detspect{ii}) * samplekeV';
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'photoncount', 2}
            % photon counting
            Pair{ii} = exp(-Dmu(1:Np*Nfocal, :)) * detspect{ii}';
            Pair{ii} = Pair{ii}.*distscale(:);
        case {'energyvector', 3}
            % maintain the components on energy
            Pair{ii} = exp(-Dmu(1:Np*Nfocal, :)).*detspect{ii};
            Pair{ii} = Pair{ii}.*distscale(:);
        otherwise
            % error
            error(['Unknown projection method: ' method]);
    end
    
end

% projection on objects
Dmu = Dmu + projectinphantom(focalposition, detector.position, phantom, samplekeV, viewangle, couch);

% effective quantum patical number normalize
% TBC

% energy based Posibility
for ii = 1:Nw
    switch lower(method)
        case {'default', 1}
            % ernergy integration
            P{ii} = (exp(-Dmu).*detspect{ii}) * samplekeV';
            P{ii} = reshape(P{ii}, Np*Nfocal, Nview/Nfocal).*distscale(:);
            P{ii} = reshape(P{ii}, Np, Nview);
        case {'photoncount', 2}
            % photon counting
            P{ii} = exp(-Dmu) * detspect{ii}';
            P{ii} = reshape(P{ii}, Np*Nfocal, Nview/Nfocal).*distscale(:);
            P{ii} = reshape(P{ii}, Np, Nview);
        case {'energyvector', 3}
            % maintain the components on energy
            P{ii} = exp(-Dmu).*detspect{ii};
            P{ii} = reshape(P{ii}, Np*Nfocal, []).*distscale(:);
            P{ii} = reshape(P{ii}, Np*Nview, []);
        otherwise
            % error
            error(['Unknown projection method: ' method]);
    end    
end

% return
Dataflow = struct();
Dataflow.samplekeV = samplekeV;
Dataflow.viewangle = viewangle;
Dataflow.couch = couch;
Dataflow.shotindex = shotindex;
Dataflow.P = P;
Dataflow.Pair = Pair;

end