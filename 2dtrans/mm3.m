function [en,tr2,tr3] = mm3(n)

% mm3(n)
%
% Calculates transmission through a 2D three-terminal device
% using n modes. Returns transmission coefficients tr2, tr3
% corresponding to energies en.

% Most notation and algorithms from
% [1] A. Weisshaar et al., Appl. Phys. Lett. 55, 2114 (1989).

% We use units of
% length = nm
% mass = m0
% energy = eV
%
% Thus we have hbar and hbar^2/2m_0 as

hbar = 0.27604281148089;
h2m = hbar^2/(2*.05); %  .067m_0 = eff. mass in GaAs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Tunable parameters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%    ---
%     |                |   3    |
%     |                |        |
%  L  |                |        |
%     |                |        |
%    ---   -------------        -------------
%     | 
%  w1 |    1                                2
%     |
%    ---   ----------------------------------
%          |-----------|--------|-----------|
%                l1        w2        l1
%

% Geometry in nanometers
w1 = 10;
w2 = 10;

% just for visualization
L  = 10;
l1 = 10;

% Incoming mode
mode = 3;

% Total energy in eV (give a vector for looping)
energy = 1.00001*h2m*pi^2/(w1^2)*mode^2 + (0:.01:1.5);
%energy = 1;

% Electrons are injected from probe dir = 1,2,3
dir = 1;

% Grid spacing is delta nanometers
delta = .1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mode matching
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Dimensions of wave data arrays
len1 = round(l1 / delta);
dimL = round(L / delta);
dim1 = round(w1/delta) + 1;
dim2 = round(w2/delta) + 1;

% Transverse wavefunctions
phi = zeros(dim1,n);
khi = zeros(dim2,n);

for m = 1:n
  for j = 1:dim1
    phi(j,m) = sqrt(2/w1)*sin(m*pi*(j-1)/(dim1-1));
  end
end

for m = 1:n
  for j = 1:dim2
    khi(j,m) = sqrt(2/w2)*sin(m*pi*(j-1)/(dim2-1));
  end
end

% Energy loop
nn = 1;
for E = energy

  % Highest propagating mode
  maxmode1 = floor(sqrt(E/h2m)*w1/pi);
  maxmode2 = floor(sqrt(E/h2m)*w2/pi);

  % k-vector arrays
  k1 = zeros(n,1);
  k2 = zeros(n,1);

  for m = 1:n
    k1(m) = sqrt(E/h2m-m^2*pi^2/w1^2);
  end

  for m = 1:n
    k2(m) = sqrt(E/h2m-m^2*pi^2/w2^2);
  end

  % The heart of the program.
  % This should be documented somewhere.
  
  A = zeros(6*n,6*n);
  xvec = (0:dim1-1)'*delta;
  zvec = (0:dim2-1)'*delta;

  % Auxiliary matrices C1..C4
  C1=zeros(n,n);
  C2=zeros(n,n);
  C3=zeros(n,n);
  C4=zeros(n,n);

  for m1 = 1:n
    for m2 = 1:n
      C1(m1,m2) = phi(:,m1).'*sin(k2(m2)*xvec)*m2*pi/w2*sqrt(2/w2)* ...
	  delta;
    end
  end

  C2 = C1;
  for m1 = 1:2:n
    C2(:,m1) = -C2(:,m1);
  end

  for m1 = 1:n
    for m2 = 1:n
      C3(m1,m2) = (-1)^m2*khi(:,m1).'*sin(k1(m2)*zvec)*m2*pi/w1*sqrt(2/w1)* ...
	  delta;
      C4(m1,m2) = (-1)^m2*khi(:,m1).'*sin(k1(m2)*(zvec-w2))*m2*pi/w1*sqrt(2/w1)* ...
	  delta;
    end
  end

  % Create mode-matching matrix A
  
  % Continuity of wavefunction at junction 1
  A(1:n,1:n)       = eye(n);
  A(1:n,4*n+1:5*n) = 1i*diag(sin(k1*w2));

  % Continuity of derivative at junction 1
  A(n+1:2*n,1:n)       = -eye(n);
  A(n+1:2*n,3*n+1:4*n) = -eye(n);
  A(n+1:2*n,4*n+1:5*n) = -diag(cos(k1*w2));
  A(n+1:2*n,5*n+1:6*n) = -diag(1./k1)*C1;

  % Continuity of wavefunction at junction 2
  A(2*n+1:3*n,n+1:2*n)   = eye(n);
  A(2*n+1:3*n,3*n+1:4*n) = -1i*diag(sin(k1*w2));

  % Continuity of derivative at junction 2
  A(3*n+1:4*n,n+1:2*n)   = eye(n);
  A(3*n+1:4*n,3*n+1:4*n) = -diag(cos(k1*w2));
  A(3*n+1:4*n,4*n+1:5*n) = -eye(n);
  A(3*n+1:4*n,5*n+1:6*n) = -diag(1./k1)*C2;

  % Continuity of wavefunction at junction 3
  A(4*n+1:5*n,2*n+1:3*n) = eye(n);
  A(4*n+1:5*n,5*n+1:6*n) = -1i*diag(sin(k2*w1));

  % Continuity of derivative at junction 3
  A(5*n+1:6*n,2*n+1:3*n) = diag(k2);
  A(5*n+1:6*n,3*n+1:4*n) = -C3;
  A(5*n+1:6*n,4*n+1:5*n) = -C4;
  A(5*n+1:6*n,5*n+1:6*n) = -diag(k2.*cos(k2*w1));

  % Amplitude vectors
  a1 = zeros(n,1);
  a2 = zeros(n,1);
  a3 = zeros(n,1);
  b1 = zeros(n,1);
  b2 = zeros(n,1);
  b3 = zeros(n,1);
  da = zeros(n,1);
  db = zeros(n,1);
  dc = zeros(n,1);

  % The values of a1, a2 and a3 are given
  if dir == 1
    a1(mode) = 1;
  elseif dir == 2
    a2(mode) = 1;
  else
    a3(mode) = 1;
  end
  
  % Solve the problem Ax = b
  b=zeros(6*n,1);
  b(1:n) = -a1;
  b(n+1:2*n) = -a1;
  b(2*n+1:3*n) = -a2;
  b(3*n+1:4*n) = a2;
  b(4*n+1:5*n) = -a3;
  b(5*n+1:6*n) = k2.*a3;
  
  x = A\b;

  b1 = x(1:n);
  b2 = x(n+1:2*n);
  b3 = x(2*n+1:3*n);
  da = x(3*n+1:4*n);
  db = x(4*n+1:5*n);
  dc = x(5*n+1:6*n);

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % T and R coefficients
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  T2 = 0;
  T3 = 0;
  R  = 0;

  if dir == 1
    for i = 1:min(n,maxmode1)
      if a1(i) ~= 0
	Ja = a1(i)'*a1(i)*k1(i);
	for j = 1:min(n,maxmode1)
	  tmp = b1(j)'*b1(j)*k1(j)/Ja;
	  sprintf('a1(%i) -> b1(%i): %.8f', i,j,tmp)
	  R = R + tmp;
	end
	for j = 1:min(n,maxmode1)
	  tmp = b2(j)'*b2(j)*k1(j)/Ja;
	  sprintf('a1(%i) -> b2(%i): %.8f', i,j,tmp)
	  T2 = T2 + tmp;
	end
	for j = 1:min(n,maxmode2)
	  tmp = b3(j)'*b3(j)*k2(j)/Ja;
	  sprintf('a1(%i) -> b3(%i): %.8f', i,j,tmp)
	  T3 = T3 + tmp;
	end
      end
    end
  
  elseif dir == 2
    
    for i = 1:min(n,maxmode1)
      if a2(i) ~= 0
	Ja = a2(i)'*a2(i)*k1(i);
	for j = 1:min(n,maxmode1)
	  tmp = b2(j)'*b2(j)*k1(j)/Ja;
	  sprintf('a2(%i) -> b2(%i): %.8f', i,j,tmp)
	  R = R + tmp;
	end
	for j = 1:min(n,maxmode1)
	  tmp = b1(j)'*b1(j)*k1(j)/Ja;
	  sprintf('a2(%i) -> b1(%i): %.8f', i,j,tmp)
	  T2 = T2 + tmp;
	end
	for j = 1:min(n,maxmode2)
	  tmp = b3(j)'*b3(j)*k2(j)/Ja;
	  sprintf('a2(%i) -> b3(%i): %.8f', i,j,tmp)
	  T3 = T3 + tmp;
	end
      end
    end
  
  else
    
    for i = 1:min(n,maxmode2)
      if a3(i) ~= 0
	Ja = a3(i)'*a3(i)*k2(i);
	for j = 1:min(n,maxmode2)
	  tmp = b3(j)'*b3(j)*k2(j)/Ja;
	  sprintf('a3(%i) -> b3(%i): %.8f', i,j,tmp)
	  R = R + tmp;
	end
	for j = 1:min(n,maxmode1)
	  tmp = b1(j)'*b1(j)*k1(j)/Ja;
	  sprintf('a3(%i) -> b1(%i): %.8f', i,j,tmp)
	  T2 = T2 + tmp;
	end
	for j = 1:min(n,maxmode1)
	  tmp = b2(j)'*b2(j)*k1(j)/Ja;
	  sprintf('a3(%i) -> b2(%i): %.8f', i,j,tmp)
	  T3 = T3 + tmp;
	end
      end
    end
  
  end
  
  sprintf('T2: %.8f  T3: %.8f  R:%.8f  T+R: %.8f', T2,T3,R,T2+T3+R)

  en(nn) = E;
  tr2(nn) = T2;
  tr3(nn) = T3;
  nn=nn+1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if length(energy) == 1  % 3D surface plot

  % Propagating exponential functions

  ex = zeros(n,len1);
  for m = 1:n
      ex(m,:) = exp(1i*k1(m)*(-len1:-1)*delta);
  end
  wave1(1:dim1,1:len1) = phi*diag(a1)*ex + phi*diag(b1)*(1./ex);
  wave1(1:dim1,len1+dim2+1:2*len1+dim2) = phi*diag(a2)*ex(:,len1:-1:1) ...
      + phi*diag(b2)*(1./ex(:,len1:-1:1));
  clear ex;

  ex1 = zeros(n,dim2);
  ex2 = zeros(n,dim1);
  for m = 1:n
      ex1(m,:) = sinh(1i*k1(m)*(0:dim2-1)*delta);
      ex2(m,:) = sinh(1i*k2(m)*(0:dim1-1)*delta);
  end
  wave1(1:dim1,len1+1:len1+dim2) = phi*diag(da)*ex1 + ...
      phi*diag(db)*(-ex1(:,dim2:-1:1)) + (khi*diag(dc)*ex2).';
  clear ex1;
  clear ex2;

  ex = zeros(n,dimL);
  for m = 1:n
      ex(m,:) = exp(1i*k2(m)*(0:dimL-1)*delta);
  end
  wave2(1:dimL,1:dim2) = (khi*diag(a3)*(1./ex)).' + ...
      (khi*diag(b3)*ex).';
  clear ex;

  subplot(1,1,1);
%  colormap(hot);
%  wave1 = real(wave1); wave2=real(wave2);
  wave1 = abs(wave1).^2;wave2 = abs(wave2).^2;
  [a,b] = view;
  surf(linspace(-l1,w2+l1,2*len1+dim2), linspace(0,w1,dim1),wave1);
  hold on;
  surf(linspace(0,w2,dim2), linspace(w1,w1+L,dimL),wave2);
  hold off;
  view(a,b);
  shading interp;
  axis tight;
  
else

  hold off;
  plot(en, tr2, '-');
  hold on;
  plot(en, tr3, '--');
  hold off;
  
end
