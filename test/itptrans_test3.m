Nx = 512;
mext = 3;
xx = (1:Nx) - (Nx+1)/2;
xx_ext = (1:Nx+mext*2) - (Nx+mext*2+1)/2;

% yy1 = xx+0.3;
Ny = 800;
yy1 = linspace(xx(1), xx(end), Ny) + 0.2;
[index1, alpha1] = interpprepare(xx_ext, yy1);

m = 100;
% X = rand(Nx, 1) + exp(-(xx(:)./Nx.*10).^2);
X = randn(Nx, m);

% X_ext = [X(1, :) + (mext:-1:1)'*(X(1,:)-X(2,:)); X; X(end, :) + (1:mext)'*(X(end,:)-X(end-1,:))];
% X_ext = [repmat(X(1,:), mext, 1); X; repmat(X(end,:), mext, 1)];
X_ext = [X(1, :).*2 - flipud(X(2:mext+1, :)); X; X(end, :).*2 - flipud(X(end-mext:end-1, :))];
% X_ext =[ones(mext, m); X; ones(mext, m)];
% X_ext = [3*X(1, :)-2*X(2, :); 2*X(1, :)-X(2, :); X; 2*X(end, :)-X(end-1, :); 3*X(end, :)-2*X(end-1, :)];
Y1_line = X_ext(index1(:,1), :).*alpha1(:,1) + X_ext(index1(:,2), :).*alpha1(:,2);

alpha = alpha1(:,2);
beta = 1/2-sqrt(1+4.*alpha.*(1-alpha))./2;
Y1 = X_ext(index1(:,1)-1, :).*(1-alpha+beta)./4 + X_ext(index1(:,1), :).*(2-alpha-beta)./4 + ...
     X_ext(index1(:,2), :).*(1+alpha-beta)./4 + X_ext(index1(:,2)+1, :).*(alpha+beta)./4;

gamma = 0.7;
Y2 = X_ext(index1(:,1)-2, :) .* (-(1-alpha+beta).*(gamma/8)) + ...                              % -2
     X_ext(index1(:,1)-1, :) .* ((1-alpha+beta)./4 + (-alpha+beta.*3).*(gamma/8)) + ...         % -1
     X_ext(index1(:,1), :) .* ((2-alpha-beta)./4 + (1-alpha-beta).*(gamma/4)) + ...             % 0
     X_ext(index1(:,2), :) .* ((1+alpha-beta)./4 + (alpha-beta).*(gamma/4)) + ...               % +1
     X_ext(index1(:,2)+1, :) .* ((alpha+beta)./4 + (alpha-1+beta.*3).*(gamma/8)) + ...           % +2
     X_ext(index1(:,2)+2, :) .* (-(alpha+beta).*(gamma/8));
     

hy = mean(diff(yy1));
ky = linspace(0, 0.5, Ny/2+1)./hy;
kx = linspace(0, 0.5, Nx/2+1);

p0 = fft(X);
p1 = fft(Y1);
p2 = fft(Y2);

% b1 = 0.4758;
% b2 = -0.0409;
% 
% A1 = spdiags(repmat([b1/2 1-b1 b1/2], Ny, 1), [-1 0 1], Ny, Ny);
% A2 = spdiags(repmat([b2/2 1-b2 b2/2], Ny, 1), [-1 0 1], Ny, Ny);
% A1(1,1) = 1 - b1/2;
% A1(end,end) = 1 - b1/2;
% A2(1,1) = 1 - b1/2;
% A2(end,end) = 1 - b1/2;
% 
% Z1 = A1\(A2*Y1);
% 
% cut = 0.01;
% k = linspace(0, 0.5, Ny/2+1);
% k = [k, -fliplr(k(2:end-1))];
% f1 = cos(k.*(pi*3)).*(2-sqrt(2))./4 + cos(k.*pi).*(2+sqrt(2))./4;
% f1(f1<cut) = 1;
% f1 = 1./f1(:);
% f1(abs(k)>0.5*hy) = 1;
% 
% Z2 = ifft(fft(Y1).*f1);

