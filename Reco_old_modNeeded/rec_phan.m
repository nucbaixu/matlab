function [phi0,phi1] = rec_phan(stack,padding,alpha,beta);
% Attempt to reconstruct the complete stack by means of Matlab arrays and
% notation.

%dimensions, number of projections
[dim2,dim1,nop] = size(stack);
dimx       = padding*2^nextpow2(dim1);
dimy       = padding*2^nextpow2(dim2);
%filter arrays
[xi,eta]   = meshgrid(-1/2:1/(dimx):1/2-1/(dimx),-1/2:1/(dimy):1/2-1/(dimy));
xi         = repmat(fftshift(xi),[1 1 nop]);
eta        = repmat(fftshift(eta),[1 1 nop]);
lap        = xi.^2 + eta.^2;
inv_lap    = 1./(lap + 10^-alpha) + beta;
% Start timer.
t1 = tic;
%zero-pad image and define g
g       = padarray(stack-1,[(dimy-dim2)/2,(dimx-dim1)/2,0],0,'both');
%FT of g
g_ft    = fft2(g,dimy,dimx);
%compute FT[phi] by inverting the  laplacian
phi0_ft = inv_lap.*g_ft;
%first order
phi0    = ifft2(phi0_ft,dimy,dimx);
%second order corrections:
iftxiphi_ft  = ifft2( xi.*phi0_ft,dimy,dimx);
iftetaphi_ft = ifft2(eta.*phi0_ft,dimy,dimx);
phi1         =  ifft2(inv_lap.*fft2( ...
               -1/2*g.^2 ... 
               -1/2* iftxiphi_ft.*ifft2( xi.*g_ft) ...
               -1/2*iftetaphi_ft.*ifft2(eta.*g_ft) ...
                               ,dimy,dimx),dimy,dimx,'symmetric') ...
               -1/4*(iftxiphi_ft.^2 + iftetaphi_ft.^2);
%take real part and clip zero-padded matrices to original size
if padding > 1
ycut = 1+dimy/2-dim2/2:dimy/2+dim2/2;
xcut = 1+dimx/2-dim1/2:dimx/2+dim1/2;
phi0      = real(phi0(ycut,xcut));
phi1      = real(phi1(ycut,xcut));
else
phi0   = real(phi0);
phi1   = real(phi1);
end;    
ranges(phi0);ranges(phi1);
%renormalize stack
minmat = repmat(min(min(phi0+phi1)),[dim2,dim1,1]);
maxmat = repmat(max(max(phi0+phi1)),[dim2,dim1,1]);
phi0   = (phi0-minmat)./(maxmat-minmat);
phi1   = (phi1)./(maxmat-minmat);
% Stop timer. Print time elapsed>
t2 = toc(t1);
fprintf(1,'Total time elapsed: %.0u s\n',t2);











