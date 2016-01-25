function mm(n1, n2)

% mm(n1, n2)
%
% Calculates transmission through a 2D potential junction
% with n1 modes to the left and n2 modes to the right of
% the junction.

% Most notation and algorithms from
% [1] A. Weisshaar et al., J. Appl. Phys. 70, 355 (1991).

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

%                -------------------
%                |        |
%  --------------         |
%    |                    |
%    | w1                 | w2
%    |                    |
%  --------------         |
%    |           |        |
%    | c         |        |
%    |           -------------------
%
%
%  |-------------|------------------|
%        l1              l2
%

% Geometry in nanometers
w1 = 20;
w2 = 10;
c  = 0;

l1 = 60;
l2 = 100;

% Total energy in eV
E=.5;

% Incoming mode (algo 1,2) or transmitted mode (algo 3)
mode = 1;

% Algorithm
% 1 = original from [1], narrow -> wide ok
% 2 = as 1, but wide -> narrow ok
% 3 = modified by J. Tulkki
algo = 2;

% Visualization
% 1 = 3D plot
% 2 = 2D plot at the junction
visual = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mode matching
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
% Grid spacing is delta nanometers
delta = .2;

% Dimensions of wave data arrays
len1 = round(l1 / delta);
len2 = round(l2 / delta);
dim1 = round(w1/delta) + 1;
dim2 = round(w2/delta) + 1;
dimc = round(c/delta);

% Highest propagating modes
maxmode1 = floor(sqrt(E/h2m)*w1/pi)
maxmode2 = floor(sqrt(E/h2m)*w2/pi)

% Transverse wavefunctions
phi1 = zeros(dim1,n1);
phi2 = zeros(dim2,n2);

for m = 1:n1
  for j = 1:dim1
    phi1(j,m) = sqrt(2/w1)*sin(m*pi*(j-1)/(dim1-1));
  end
end

for m = 1:n2
  for j = 1:dim2
    phi2(j,m) = sqrt(2/w2)*sin(m*pi*(j-1)/(dim2-1));
  end
end

% Overlap matrix
C=zeros(n2, n1);

for m1 = 1:n1
  for m2 = 1:n2
    C(m2,m1) = phi1(max(-dimc+1,1):min(dim1,dim2-dimc), m1)'*...
	phi2(max(1,dimc+1):min(dim2,dim1+dimc),m2)*delta;
  end
end

% k-vector arrays
k1 = zeros(n1,1);
k2 = zeros(n2,1);

for m = 1:n1
  k1(m) = sqrt(E/h2m-m^2*pi^2/w1^2);
end

for m = 1:n2
  k2(m) = sqrt(E/h2m-m^2*pi^2/w2^2);
end

% See [1]
K1=diag(k1);
K2=diag(k2);
H2=-inv(K1)*C.'*K2;

if algo == 1
  
  % Incoming wave
  a1=zeros(n1,1);
  a1(mode)=1;

  % Amplitudes of reflected and transmitted waves
  S11=inv(eye(n1)-H2*C)*(eye(n1)+H2*C);
  S21=C*(eye(n1)+S11);
  b1 = S11*a1
  b2 = S21*a1

elseif algo == 2
  
  % Incoming wave
  a1=zeros(n1,1);
  a1(mode)=1;

  % Amplitudes of reflected and transmitted waves
  b1 = inv(eye(n1)+C'*inv(K2)*C*K1)*(-eye(n1)+C'*inv(K2)*C*K1)*a1
  b2 = 2*inv(C*K1*C'+K2)*C*K1*a1

else
  
  % Transmitted wave
  b2=zeros(n2,1);
  b2(mode)=1;

  % Amplitudes of incoming and reflected waves
  a1 = .5*(C'-H2)*b2;
  b1 = .5*(C'+H2)*b2;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% T and R coefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

T=0;
R=0;

for i = 1:min(maxmode1,n1)
  if a1(i) ~= 0
    Ja1 = a1(i)'*a1(i)*k1(i);
    for j = 1:min(maxmode1,n1)
      tmp = b1(j)'*b1(j)*k1(j)/Ja1;
      sprintf('A%i -> A%i: %.8f', i,j,tmp)
      R = R + tmp;
    end
    for j = 1:min(maxmode2,n2)
      tmp = b2(j)'*b2(j)*k2(j)/Ja1;
      sprintf('A%i -> B%i: %.8f', i,j,tmp)
      T = T + tmp;
    end
  end
end

sprintf('T: %.8f  R:%.8f  T+R: %.8f', T,R,T+R)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Visualization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if visual == 1  % 3D surface plot

  % Propagating exponential functions
  ex1 = zeros(n1,len1);
  ex2 = zeros(n2,len2);

  for m = 1:n1
    for j = 1:len1
      ex1(m,len1+1-j) = exp(1i*k1(m)*j*delta);
    end
  end
  
  for m = 1:n2
    for j = 1:len2
      ex2(m,j) = exp(1i*k2(m)*(j-1)*delta);
    end
  end
  
  % Show only modes idx (inc, refl, trans)
  idxi=1:n1;
  idxr=1:n1;
  idxt=1:n2;
  wave1 = phi1(:,idxr)*diag(b1(idxr))*ex1(idxr,:);
  wave1 = wave1 + phi1(:,idxi)*diag(a1(idxi))*(1./ex1(idxi,:));
  wave2 = phi2(:,idxt)*diag(b2(idxt))*ex2(idxt,:);

  maxdim = max(dimc+dim1,dim2)+max(0,-dimc);
  wave=zeros(maxdim, len1+len2);
  if dimc < 0
    wave(1:dim1,1:len1)=wave1;
    wave((1-dimc):(dim2-dimc),(len1+1):(len1+len2))=wave2;
  else
    wave(dimc+1:(dimc+dim1),1:len1)=wave1;
    wave(1:dim2,(len1+1):(len1+len2))=wave2;
  end
  colormap(hot);
%  wave = real(wave);
  wave = abs(wave).^2;
  [a,b] = view;
  surf(linspace(-l1,l2,len1+len2), ...
       linspace(min(0,c),max(c+w1,w2),maxdim),wave);
  view(a,b);
  shading interp;
  axis tight;
  
else  % 2D plot
  
  plotderiv = 0;
  
  if plotderiv == 0
    wave1 = phi1*b1;
    wave1 = wave1 + phi1*a1;
    wave2 = phi2 * b2;
  else
    wave1 = -phi1*K1*b1;
    wave1 = wave1 + phi1*K1*a1;
    wave2 = phi2*K2*b2;
  end
  plot(linspace(c,c+w1,dim1), real(wave1),'r');
  hold on;
  plot(linspace(0,w2,dim2), real(wave2),'b');
  hold off;

end
