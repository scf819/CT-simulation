Cimage = phantom().*100;
Oimg = [0 0 0];

[Nx, Ny] = size(Cimage);

Np = 500;
A = [0 -200 0];
B = [linspace(-200, 200, Np)' ones(Np,1).*200 zeros(Np,1)];
h = 1;

theta = 0.1;

% go
Cimage_ext = [Cimage(:); 0];
Next = Nx*Ny+1;
% Lxy is the length of AB on xy plane
Lxy = sqrt((B(:,1)-A(:,1)).^2 + (B(:,2)-A(:,2)).^2);
% Lo is the length from ISO to A (on xy plane)
Lo = sqrt(A(:,1).^2 + A(:,2).^2);

% % d is the distance from ISO to AB
% d = (A(:,2).*B(:,1)-A(:,1).*B(:,2))./Lxy;
% Lmid = sqrt(A(:,1).^2+A(:,2).^2-d.^2);
        
% Xgrid = -(Nx-1)/2:(Nx-1)/2;
% Ygrid = -(Ny-1)/2:(Ny-1)/2; 

Rt = 100;
t = 0.9;
tgrid = [fliplr(0:-t:-Rt) (t:t:Rt)]' + Lo;
Nt = length(tgrid);

Psample = reshape(reshape((B - A)./Lxy, [], 1)*tgrid', Np, 3, Nt) + A;
Psample = reshape(permute(Psample, [1 3 2]), [], 3);

Rp2 = sum(Psample.^2, 2);
Sp = Rp2<Rt^2;
P0 = Psample(Sp, :);

Mrot = [cos(theta)  sin(theta)    0;
       -sin(theta)  cos(theta)    0;
        0               0         1];
Pv = P0*Mrot - 0.5;

index_xy = floor(Pv(:, [1 2]));
alpha_xy = Pv(:, [1 2]) - index_xy;
index_xy = index_xy + [Nx/2+1 Ny/2];
sout = any((index_xy<[1 0]) | (index_xy>[Nx-1 Ny-2]), 2);

index_xy1 = index_xy*[1; Nx];
index_intp = [index_xy1  index_xy1+1  index_xy1+Nx  index_xy1+Nx+1];
index_intp(sout, :) = Next;
alpha_intp = [(1-alpha_xy(:,1)).*(1-alpha_xy(:,2))  alpha_xy(:,1).*(1-alpha_xy(:,2))  (1-alpha_xy(:,1)).*alpha_xy(:,2)  alpha_xy(:,1).*alpha_xy(:,2)];

Dintp = sum(Cimage_ext(index_intp).*alpha_intp, 2);
Dsample = zeros(Np, Nt);
Dsample(Sp) = Dintp;


