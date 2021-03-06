function [dataflow, prmflow, status] = reconnode_BPprepare(dataflow, prmflow, status)
% recon node, BP prepare, set FOV, image size, center (XYZ), tilt ... for the images
% [dataflow, prmflow, status] = reconnode_BPprepare(dataflow, prmflow, status);

% BP parameters
BPprm = prmflow.pipe.(status.nodename);

% FOV
if isfield(BPprm, 'FOV')
    prmflow.recon.FOV = BPprm.FOV;
elseif isfield(prmflow.protocol, 'reconFOV')
    prmflow.recon.FOV = prmflow.protocol.reconFOV;
else
    % default FOV = 500
    prmflow.recon.FOV = 500;
end
% imagesize
if isfield(BPprm, 'imagesize')
    prmflow.recon.imagesize = BPprm.imagesize;
elseif isfield(prmflow.protocol, 'imagesize')
    prmflow.recon.imagesize = prmflow.protocol.imagesize;
else
    % default imagesize = 512
    prmflow.recon.imagesize = 512;
end
% image XY
if isfield(BPprm, 'center')
    prmflow.recon.center = BPprm.center;
else
    prmflow.recon.center = prmflow.protocol.reconcenter;
end
% max radius
if isfield(BPprm, 'maxradius')
    prmflow.recon.maxradius = BPprm.maxradius;
else
%     maxradius = sqrt(sum(max(abs(prmflow.recon.center(1:2, :)), 1) + prmflow.recon.FOV/2).^2); % why?
    prmflow.recon.maxradius = 250.01;
end
% window
if isfield(BPprm, 'windowcenter')
    prmflow.recon.windowcenter = BPprm.windowcenter;
else
    prmflow.recon.windowcenter = prmflow.protocol.windowcenter;
end
if isfield(BPprm, 'windowwidth')
    prmflow.recon.windowwidth = BPprm.windowwidth;
else
    prmflow.recon.windowwidth = prmflow.protocol.windowwidth;
end
% kernel
if isfield(BPprm, 'kernel')
    prmflow.recon.kernel = BPprm.kernel;
elseif isfield(prmflow.protocol, 'reconkernel')
    prmflow.recon.kernel = prmflow.protocol.reconkernel;
else
    % default kernel?
    prmflow.recon.kernel = '';
end
% imagethickness & imageincrement
if isfield(prmflow.system, 'nominalslicethickness') && ~isempty(prmflow.system.nominalslicethickness)
    % The real image/slice thickness could not exactly equal to the nominal thickness, 
    % e.g. the nominal thickness could be 0.625 but the real thickness is 0.6222
    zscale = prmflow.system.detector.hz_ISO/prmflow.system.nominalslicethickness;
    prmflow.recon.imagethickness = prmflow.protocol.imagethickness * zscale;
    prmflow.recon.imageincrement = prmflow.protocol.imageincrement * zscale;
else
    prmflow.recon.imagethickness = prmflow.protocol.imagethickness;
    prmflow.recon.imageincrement = prmflow.protocol.imageincrement;
end
% tilt
prmflow.recon.gantrytilt = prmflow.protocol.gantrytilt*(pi/180);
% couch (table) step & couch direction
prmflow.recon.shotcouchstep = prmflow.protocol.shotcouchstep;
prmflow.recon.couchdirection = prmflow.protocol.couchdirection;
% startcouch
prmflow.recon.startcouch = prmflow.protocol.startcouch;

switch lower(prmflow.recon.scan)
    case 'axial'
        prmflow.recon.Nimage = prmflow.recon.Nslice * prmflow.recon.Nshot;
        prmflow.recon.imagecenter = imagescenterintilt(prmflow.recon.center, prmflow.recon);
    otherwise
        warning('sorry, only Axial now.');
        % only Axial now
end

% status
status.jobdone = true;
status.errorcode = 0;
status.errormsg = [];
end


function Cout = imagescenterintilt(Cin, recon)
% Cin is recon center; Cout is the rotation center on images
% 'small-step' style for tilt shots 

Cout = repmat(-Cin(:)', recon.Nimage, 1);
% Y shfit
% Yshift = -(recon.imageincrement*tan(recon.gantrytilt)).*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
Yshift = -(recon.imageincrement*sin(recon.gantrytilt)).*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
if recon.couchdirection > 0
    Yshift = fliplr(Yshift);
end
Yshift = repmat(Yshift(:), recon.Nshot, 1);
Cout(:, 2) = Cout(:, 2) + Yshift;
% Z shift
% Zshift = (recon.imageincrement*sec(recon.gantrytilt)).*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
Zshift = recon.imageincrement.*(-(recon.Nslice-1)/2 : (recon.Nslice-1)/2);
if recon.couchdirection > 0
    Zshift = fliplr(Zshift);
end
Zshift = Zshift(:) - (0:recon.Nshot-1).*recon.shotcouchstep;
Zshift = Zshift(:) - recon.startcouch;
Cout = [Cout Zshift];

end
