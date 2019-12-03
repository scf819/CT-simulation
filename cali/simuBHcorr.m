% function corrpoly = simuBHcorr(SYS, response, n)

% test
xr = [486.2832  848.6392  927.3556  734.1626  711.6979];
spectrange = [20, 150];
t = linspace(spectrange(1), spectrange(2), Nx+1);
xt = [0; 0; xr(:); 0];
cs = spline(t, xt);
response = ppval(cs, samplekeV(:));
response(samplekeV(:)<20) = 0;

bowtie = SYS.collimation.bowtie;
filter = SYS.collimation.filter;
samplekeV = SYS.world.samplekeV;
focalpos = SYS.source.focalposition(1,:);
Npixel = SYS.detector.Npixel;
Nslice = SYS.detector.Nslice;
detpos = double(SYS.detector.position);
Nsample = length(samplekeV(:));
refrencekeV = SYS.world.refrencekeV;

Nbow = length(bowtie(:));

Dwater = 2:2:600;
mu_water = SYS.world.water.material.mu_total;
mu_weff = interp1(samplekeV, mu_water, refrencekeV);
Dwmu = -Dwater(:)*mu_water(:)';
Ndw = length(Dwater);

[Dfmu, ~] = flewoverbowtie(focalpos, detpos, bowtie, filter, samplekeV);
Dempty = -log(samplekeV*response)./mu_weff;
Dfilter = reshape(-log(exp(-Dfmu)*(samplekeV(:).*response))./mu_weff, Npixel, Nslice);
Deff = Dfilter-Dempty;
Dfmu = reshape(Dfmu, Npixel, Nslice, Nsample);

ilsice = 1;
% for islice = 1:Nslice
    [Deff_ii, sort_eff] = sort(Deff(:, islice));
    Dfmu_ii = squeeze(Dfmu(sort_eff, islice, :));
    % simplify
    Nsmp = 200;
    d_effsamp = floor((Deff_ii-min(Deff_ii))./(max(Deff_ii)-min(Deff_ii)).*Nsmp);
    [d_samp, i_samp] = unique(d_effsamp);
    Nrep = length(i_samp);
    Deff_ii = repmat(Deff_ii(i_samp), 1, Ndw);
    Dfmu_ii = Dfmu_ii(i_samp, :);
    Dfilter_ii = Dfilter(sort_eff, islice);
    Dfilter_ii = Dfilter_ii(i_samp);
      
    Pii = exp(-repmat(Dfmu_ii, Ndw, 1)+repelem(Dwmu, Nrep, 1))*(samplekeV(:).*response);
    Dii = reshape(-log(Pii)./mu_weff, Nrep, Ndw) - Dfilter_ii;
    Dtarget = Dwater./Dii;
    m = 4; n = 3;
    x0 = zeros(m*n, 1);
    x0(1) = 1;
    a = 400; b = 100;
    tic;
    x = lsqnonlin(@(x) polyval2dm(reshape(x, m, n), Dii(:)./a, Deff_ii(:)./b) - Dtarget(:), x0);
    toc
    
    
% end