% nonlinear calibration test

% % load data
% datapath = 'E:\data\rawdata\bhtest\';
% datafile = {'df_w200c.mat', 'df_w200off100.mat', 'df_w300c.mat', 'df_w300off100.mat'};
% Nf = length(datafile);
% df = cell(1, Nf);
% for ifile = 1:Nf
%     df{ifile} = load(fullfile(datapath, datafile{ifile}));
% end

% Npixel = 864;
% Nslice = 64;
% Nview = 1152;
% 
% m = 16;
% cut = 1e3;
% 
% A = cell(1, Nf);
% B = cell(1, Nf);
% for ifile = 1:Nf
%     A{ifile} = reshape(df{ifile}.rawdata, Npixel, []);
%     B{ifile} = reshape(df{ifile}.rawdata_bh, Npixel, []);
%     for iv = 1:Nview*Nslice
%         ix_l = find(A{ifile}(:, iv)>cut, 1, 'first');
%         ix_r = find(A{ifile}(:, iv)>cut, 1, 'last');
%         A{ifile}([1:ix_l+m-1 ix_r-m+1:Npixel], iv) = 0;
%         B{ifile}([1:ix_l+m-1 ix_r-m+1:Npixel], iv) = 0;
%     end
%     A{ifile} = reshape(A{ifile}, [], Nview);
%     B{ifile} = reshape(B{ifile}, [], Nview);
% end



% % non-linear1
% n = 2;
% p = nan(Npixel*Nslice, n);
% t0 = zeros(1, n);
% t0(n) = 1.0;
% K = 1.0;
% options = optimoptions('lsqnonlin','Display','off');
% % ipx = 400;
% sy = zeros(Npixel,1);
% for ipx = 1:Npixel*Nslice
%     x = double([B{2}(ipx, :) B{4}(ipx, :)]./(1000*K));
%     y = double([A{2}(ipx, :) A{4}(ipx, :)]./(1000*K));
%     s = y>0;
%     sy(ipx) = sum(s);
%     if sy(ipx)<Nview/2
%         continue;
%     end
%     p_ipx = lsqnonlin(@(t) (iterpolyval(t, x(s))-y(s)), t0, [], [], options);
% %     t0 = p_ipx;
%     p(ipx, :) = p_ipx;
% end
% 
% p = reshape(fillmissing(reshape(p, Npixel, []), 'nearest'), [], n);

% % or load saved p
% pdata = load('E:\data\rawdata\bhtest\p_n2.mat');
% p = pdata.p;
% 
% % marged A B
% Nmerge = 8;
% Nslice_mg = Nslice/Nmerge;
% Amg = cell(1, Nf);
% Bmg = cell(1, Nf);
% for ifile = 1:Nf
%     % Amerge
%     Amg{ifile} = A{ifile}./1000;
%     Amg{ifile}(A{ifile}==0) = nan;
%     Amg{ifile} = reshape(mean(reshape(Amg{ifile}, Npixel, Nmerge, Nslice_mg*Nview), 2), Npixel*Nslice_mg, Nview);
%     Amg{ifile}(isnan(Amg{ifile})) = 0;
%     % Bmerge
%     Bmg{ifile} = B{ifile}./1000;
%     Bmg{ifile}(B{ifile}==0) = nan;
%     % correct B
%     Bmg{ifile} = iterpolyval(p, Bmg{ifile});
%     Bmg{ifile} = reshape(mean(reshape(Bmg{ifile}, Npixel, Nmerge, Nslice_mg*Nview), 2), Npixel*Nslice_mg, Nview);
%     Bmg{ifile}(isnan(Bmg{ifile})) = 0;
% end


% cross talk
% for ipx = 1:Npixel*Nslice_mg
p = zeros(Npixel, 1);
lambda = 2.0;
m_mod = 16;
start_mod = 7;
end_mod = 7;
Np1 = m_mod*(start_mod-1)+1;
Np2 = Npixel-m_mod*(end_mod-1);
for ipx = Np1:Np2
% for ipx = 417
    x = double([Bmg{2}(ipx-1:ipx+1, :) Bmg{4}(ipx-1:ipx+1, :)]);
    y = double([Amg{2}(ipx, :) Amg{4}(ipx, :)]);
    s = all(x>0);
    x = x(:, s);
    y = y(s);
    p(ipx) = lsqnonlin(@(t) crossfit1(t, x, y, lambda), 0);
end

mp = mean(reshape(p(Np1:Np2), m_mod, []), 2);




