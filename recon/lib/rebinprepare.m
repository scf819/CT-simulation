function rebin = rebinprepare(detector, focalposition, Nview_rot, isQDO)
% rebin prepare
% recon = rebinprepare(detector, Nview);
% detector is the struct of detector corr
% Nview_rot is the view number per rotation

if nargin<4
    isQDO = false;
end

% parameters to use
Npixel = double(detector.Npixel);
Nslice = double(detector.Nmergedslice);
mid_U = single(detector.mid_U);
Nps = Npixel*Nslice;
hx_ISO = detector.hx_ISO;

% fan angles
y = detector.position(1:Npixel, 2) - focalposition(2);
x = detector.position(1:Npixel, 1) - focalposition(1);
fanangles = atan2(y, x);
% I know the fanangles of each slice are equal

% perpare for Azi rebin
delta_view = pi*2/Nview_rot;
f = fanangles./delta_view;
viewindex = double(floor(f));
rebin.interalpha_azi = repmat(f-viewindex, Nslice, 1);
viewindex = viewindex + 1;  % start from 0
rebin.startvindex = mod(max(viewindex), Nview_rot)+1;
viewindex = repmat(viewindex, Nslice, Nview_rot) + repmat(0:Nview_rot-1, Nps, 1);
rebin.vindex1_azi = mod(viewindex-1, Nview_rot).*Nps + repmat((1:Nps)', 1, Nview_rot);
rebin.vindex2_azi = mod(viewindex, Nview_rot).*Nps + repmat((1:Nps)', 1, Nview_rot);

% prepar for radial rebin
if isQDO
    % QDO order
    [a1, a2] = QDOorder(Npixel, mid_U);
    s1 = ~isnan(a1);
    s2 = ~isnan(a2);
    rebin.Npixel = max([a1, a2]);
    rebin.QDOorder = [a1; a2];
    % d0 is the distance from ray to ISO
    d0 = -detector.SID.*cos(fanangles);
    % QDO d
    d = nan(rebin.N_QDO, q);
    d(a1(s1)) = d0(s1);
    d(a2(s2)) = -d0(s2);
    % delta_t and mid_t
    delta_t = hx_ISO/2.0;
    mid_t = 0.5;
else
    rebin.Npixel = Npixel;
    d = -detector.SID.*cos(fanangles);
    delta_t = detector.hx_ISO;
    mid_t = mod(detector.mid_U, 1);
end
% radial interp grid
t1 = ceil(min(d)/delta_t + mid_t);
t2 = floor(max(d)/delta_t + mid_t);
Nreb = t2-t1+1;
tt = ((t1:t2)-mid_t)'.*delta_t;
% interp index
fd = d_QDO./delta_t + mid_t;
dindex = floor(fd) - t1 + 2;
dindex(dindex<=0) = 1;
dindex(dindex>Nreb) = Nreb+1;
tindex = nan(Nreb+1, 1);
tindex(dindex) = 1:rebin.Npixel;
tindex = fillmissing(tindex(1:end-1), 'previous');
% got it
rebin.radialindex = tindex;
rebin.interalpha_rad = (tt - d(tindex))./(d(tindex+1)-d(tindex));
% midchannel
rebin.midchannel = -t1+1+mid_t;

end