function A = offfocalconv(A, detector, focalposition, Nviewprot, offwidth, offintensity)
% off-focal convolution (only axial now)
% A = offfocalconv(A, detector, focalposition, Nviewprot, offwidth, offintensity);
% A is the raw data on fan beam

SID = detector.SID;
SDD = detector.SDD;
DonL = SID/SDD;

Npixel = double(detector.Npixel);
Nslice = double(detector.Nslice);
% mid_U = single(detector.mid_U);
Nps = Npixel*Nslice;
A = reshape(A, Nps, Nviewprot);

% fan angles
y = detector.position(1:Npixel, 2) - focalposition(2);
x = detector.position(1:Npixel, 1) - focalposition(1);
fanangles = atan2(y, x);

% off-focal geodetic line
alpha = acos(DonL);
phi = fanangles-pi/2;
phi_off = phi - atan( sin(phi).*sin(alpha)./(cos(phi)-cos(alpha)) ) ./ sin(alpha);
% y1 = phi-log((cos(alpha)-cos(phi)-1i.*sin(phi).*sin(alpha))./(cos(alpha)*cos(phi)-1))./sqrt(cos(alpha)^2-1);
% I know phi_off = real(y1)

% off-focal tau-measure
t_off = tan(phi - phi_off);
offsample = max(2^ceil(log2(Npixel)), 64);  % =1024
t = linspace(min(t_off), max(t_off), offsample);
% prepare the interpolation on the measure
[t_index, t_alpha] = interpprepare(t_off, t(:), 'extrap');

% off-focal kernel (sinc-window)
p_off = offwidth/SID/(max(t_off)-min(t_off));
tt = [0:offsample/2, -offsample/2+1:-1]';
offkernel = sinc(p_off.*tt).*offintensity;

% to interplate the raw data to off-focal geodetic line
delta_view = pi*2/Nviewprot;
f = (phi_off - phi)./delta_view;
intp_idx0 = floor(f);
intp_alpha = f-intp_idx0;
intp_alpha = repmat(intp_alpha, Nslice, 1);
% to interplate on all the views
index_v = 1:Nviewprot;
intp_idx1 = mod(intp_idx0 + index_v - 1, Nviewprot);
intp_idx2 = mod(intp_idx1, Nviewprot);
intp_idx1 = repmat(intp_idx1.*Nps, Nslice, 1) + (1:Nps)';
intp_idx2 = repmat(intp_idx2.*Nps, Nslice, 1) + (1:Nps)';
Aoff = A(intp_idx1).*(1-intp_alpha) + A(intp_idx2).*intp_alpha;
Aoff = reshape(Aoff, Npixel, []);

% to interplate the Aoff to tau-measure
Aoff = Aoff(t_index(:,1),:).*t_alpha(:,1) + Aoff(t_index(:,2),:).*t_alpha(:,2);

% convolution by off-focal kernel
Aoff = ifft(fft(Aoff, offsample).*offkernel,'symmetric');

% to interplate back the Aoff from tau-measure to off-focal geodetic line
[tb_index, tb_alpha] = interpprepare(t(:), t_off, 'extrap');
Aoff = Aoff(tb_index(:,1),:).*tb_alpha(:,1) + Aoff(tb_index(:,2),:).*tb_alpha(:,2);
Aoff = reshape(Aoff, Nps, Nviewprot);

% to interplate back to fan beam and add to raw data
A = A.*(1-offintensity);
A(intp_idx1) = A(intp_idx1) + Aoff.*(1-intp_alpha);
A(intp_idx2) = A(intp_idx2) + Aoff.*intp_alpha;

end