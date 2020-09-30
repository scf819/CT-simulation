function [dt, Vindex] = linesinimageLI2D(theta, d, L, AO, Xgrid, Ygrid)
% insections of lines in grid-cells image, 2D. linear interp
% [dt, Vindex] = linesinimage2D(theta, d, L, AO, Xgrid, Ygrid);
% then D = sum(dt.*Cimage(Vindex), 2); 
% remember to add a 0 after Cimage that Cimage = [Cimage(:); 0]
% for infinite lines, use:
% [dt, Vindex] = linesinimage2D(theta, d, [], 0, Xgrid, Ygrid);

% the numbers
N = size(theta, 1);
Nx = size(Xgrid(:),1);
Ny = size(Ygrid(:),1);
Nc = Nx*Ny+1;
% set h = 1
h = 1.0;
% mod theta with 2pi
theta = mod(theta, pi*2);
% I know theta = theta(:); d = d(:);

% loop 2 phase
phase_flag = (theta>pi/4 & theta<=pi*3/4) | (theta>pi*5/4 & theta<=pi*7/4);
for iphase = [1 0]
    if iphase
        vangle = theta(phase_flag);
        d_h = d(phase_flag)./h;
        dt_i = tan(pi/2-vangle);
        cs_vangle = csc(vangle);
        Nx_x = Nx;
        Ny_y = Ny;
    else
        vangle = theta(~phase_flag);
        d_h = d(~phase_flag)./h;
        dt_i = tan(vangle);
        cs_vangle = -sec(vangle);
        Nx_x = Ny;
        Ny_y = Nx;
    end
    
    t = dt_i*(-(Ny_y-1)/2:(Ny_y-1)/2) - repmat(d_h.*cs_vangle, 1, Ny_y) + 1/2;
    index_1 = floor(t);
    inter_alpha = t - index_1;

    index_1 = index_1 + Nx_x/2;
    index_2 = index_1 + 1;
    s1 = index_1<=0 | index_1>Nx_x;
    s2 = index_2<=0 | index_2>Nx_x;
    if phase_flag
        index_1 = index_1 + repmat((0:Ny-1).*Nx, Np, 1);
        index_2 = index_2 + repmat((0:Ny-1).*Nx, Np, 1);
    else
        index_1 = (index_1-1).*Nx + repmat(1:Nx, Np, 1);
        index_2 = (index_2-1).*Nx + repmat(1:Nx, Np, 1);
    end
    index_1(s1) = Nc+1;
    index_2(s1) = Nc+1;
    
end

return