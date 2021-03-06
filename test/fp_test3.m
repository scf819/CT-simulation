Cimage = phantom().*100;
Oimg = [0 0 0];

[Nx, Ny] = size(Cimage);

Np = 500;
A = [0 -200 0];
B = [linspace(-200, 200, Np)' ones(Np,1).*200 zeros(Np,1)];
h = 1;

Nview = 360;
views = linspace(0, pi*2*(Nview-1)/Nview, Nview);

maxview = 360;
v1 = 1;
v2 = maxview;

% go
Cimage_ext = [Cimage(:); 0];
Next = Nx*Ny+1;
% Lxy is the length of AB on xy plane
Lxy = sqrt((B(:,1)-A(:,1)).^2 + (B(:,2)-A(:,2)).^2);

% d is the distance from ISO to AB
d = (A(:,2).*B(:,1)-A(:,1).*B(:,2))./Lxy;
Lmid = sqrt(A(:,1).^2+A(:,2).^2-d.^2);

tic;
% 0, 1, 2
D0 = zeros(Np, Nv);
D1 = zeros(Np, Nv);
D2 = zeros(Np, Nv);
Xgrid = -Nx/2:Nx/2;
Ygrid = -Ny/2:Ny/2;
for iview = v1:v2
    Mrot = [cos(views(iview))  sin(views(iview))    0;
           -sin(views(iview))  cos(views(iview))    0;
            0                  0                    1];
    % angles
    Arot = A*Mrot;
    Brot = B*Mrot;
    theta = atan2(Brot(:,2)-Arot(:,2), Brot(:,1)-Arot(:,1));
%     % 0
%     [dt, Vindex] = linesinimage2D(theta, d, Lxy, Lmid, Xgrid, Ygrid);
%     D0(:, iview) = sum(dt.*Cimage_ext(Vindex), 2);
    % 1
    [inter_alpha, index_1, index_2, cs_vangle] = linesinimageLI2D(Nx, Ny, d, theta);
    D1(:, iview) = sum(Cimage_ext(index_1).*(1-inter_alpha) + Cimage_ext(index_2).*inter_alpha, 2).*cs_vangle;
    % 2
    [inter_alpha1, inter_alpha2, index_1, index_2, cs_vangle] = linesinimageLI2D2(Nx, Ny, d, theta, Lmid, Lxy);
    D2(:, iview) = sum(Cimage_ext(index_1).*inter_alpha1 + Cimage_ext(index_2).*inter_alpha2, 2).*cs_vangle;
end
toc;
