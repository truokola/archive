function bound2(n)
%
% bound2(n)
%
% Calculates the nth bound state in a 2D geometry.

% We use units of
% length = nm
% mass = m0
% energy = eV
%
% Thus we have hbar and hbar^2/2m_0 as

hbar = 0.27604281148089;
h2m = hbar^2/(2*.067); %  .067m_0 = eff. mass in GaAs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Geometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%              |------------------
%              |                 |
%  ------------|                 |
%  |                             | w2
%  | w1                          |
%  |                             |
%  -------------------------------
%
%  |-----------|-----------------|
%        l1              l2
%
% Size in nanometers

w1 = 15;
w2 = 10;

l1 = 30;
l2 = 30;

% Array dimensions

delta = .5; % Grid spacing in nm

len1 = round(l1 / delta);
len2 = round(l2 / delta);
dim1 = round(w1/delta);
dim2 = round(w2/delta);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Construct the Laplacian and solve the boundary value problem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

L = sparse([]);

step = dim2-dim1;
s1 = dim1*len1;

diag1 = sparse(-4*diag(ones(dim1,1)) + diag(ones(dim1-1,1),1) +...
	diag(ones(dim1-1,1),-1));
ones1 = sparse(diag(ones(dim1,1)));

diag2 = sparse(-4*diag(ones(dim2,1)) + diag(ones(dim2-1,1),1) +...
	diag(ones(dim2-1,1),-1));
ones2 = sparse(diag(ones(dim2,1)));

for i=0:len1-1
  L((i*dim1+1):((i+1)*dim1), (i*dim1+1):((i+1)*dim1)) = diag1;
  if i > 0
    L((i*dim1+1):((i+1)*dim1),((i-1)*dim1+1):(i*dim1)) = ones1;
  end
  if i < len1-1
    L((i*dim1+1):((i+1)*dim1),((i+1)*dim1+1):((i+2)*dim1)) = ones1;
  else
    if step >= 0
      L((i*dim1+1):((i+1)*dim1),((i+1)*dim1+1+step):((i+2)*dim1+step)) = ones1;
    else
      L((i*dim1+1-step):((i+1)*dim1),((i+1)*dim1+1):((i+2)*dim1+step)) = ones2;
    end
  end
end


for i=0:len2-1
  L((s1+i*dim2+1):(s1+(i+1)*dim2), (s1+i*dim2+1):(s1+(i+1)*dim2)) = diag2;
  if i > 0
    L((s1+i*dim2+1):(s1+(i+1)*dim2),(s1+(i-1)*dim2+1):(s1+i*dim2)) = ones2;
  else
    if step <= 0 
      L((s1+i*dim2+1):(s1+(i+1)*dim2),(s1+(i-1)*dim2+1):(s1+i*dim2)) = ones2;
    else
      L((s1+i*dim2+1+step):(s1+(i+1)*dim2),(s1+(i-1)*dim2+1+step):(s1+i*dim2)) = ones1;
    end
  end
  if i < len2-1
    L(s1+(i*dim2+1):(s1+(i+1)*dim2),(s1+(i+1)*dim2+1):(s1+(i+2)*dim2)) = ones2;
  end
end

% Print the Laplace matrix
%printm(L)

% Solve eigenvalues using Matlab's Arnoldi iteration
[V,D] = eigs(L,n,'SM');

% Calculate the energy of state n (in eV)
E = -D(n,n) * h2m / delta^2

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Prob. density for nth state
v = V(:,n).^2;

% v is a vector, put it in matrix form
wave = zeros(max(dim1,dim2)+2, len1+len2+2); % +2 for 0-borders
tmp = reshape(v(1:s1),dim1,len1);
wave(2:(dim1+1),2:(len1+1)) = tmp(dim1:-1:1,:);
tmp = reshape(v((s1+1):(s1+len2*dim2)),dim2,len2);
wave(2:(dim2+1),(len1+2):(len1+len2+1)) = tmp(dim2:-1:1,:);

% Draw it
colormap(hot);
[a,b]=view;
surf(linspace(-l1,l2,len1+len2+2), linspace(0,max(w1,w2),max(dim1,dim2)+2), wave);
view(a,b);
shading interp;
