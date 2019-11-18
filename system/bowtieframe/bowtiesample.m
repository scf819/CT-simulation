function bowtie_corr = bowtiesample()
% bowtie corr sample
% WARN: DO NOT COPY THIS CURVE TO REAL PRODUCT

% smample curves
minthick = 2;
maxthick = 50;
length = 180;
curve1 = bowtiecurvesample(minthick, maxthick, length, 12.5, 0.18);
curve2 = bowtiecurvesample(minthick, maxthick, length, 16.5, 0.14);

% corr struct
bowtie_corr.ID = uint8([0 0 0 0]);
bowtie_corr.box = single([140, 20, 50]);
bowtie_corr.focaltobottom = single(150);
bowtie_corr.Ncurve = uint32(2);
bowtie_corr.Nsample = uint32(2);
bowtie_corr.main = single([curve1 curve2(:,2)]);

end

