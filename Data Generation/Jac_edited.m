function e_n = Jac_edited(gam, y0)
% Lammert (2020) - PDW Model Sandbox, Estimate Jacobian

% Lessons Learned:
% 1. The analytical Jacobian is only for Theta (I think), thus 2x2.
% 2. The simulation for certain configurations results in no movement.
%     It's not clear why this happens, but I currently discard those
%     solutions in the numerical Jacobian estimation procedure.
%     Need to get to the bottom of why those solutions exist.

% Setup
% gam = 0.01; % 0.01 recommended by Garcia, 0.005 recommended by Garcia
stable = 0; % 0 if gait is stable 1 if gait is unstable
steps = 1;
n = 1000; % number of simulation iterations
c = 1e-6; % perturbation size
period = 'long'; % 'short' or 'long'

if strcmp(period,'short')  
    % IC constants - short period
    Theta00 = 0.943976;
    Theta10 = -0.264561;
    alpha = -1.090331;
    c1 = 0.866610;
elseif strcmp(period,'long')
    % IC constants - long period
    Theta00 = 0.970956;
    Theta10 = -0.270837;
    alpha = -1.045203;
    c1 = 1.062895;
else
    error('period must be specified as short or long')
end

% Calculate STABLE ICs from theoretically determined equations
% tgam3 = Theta00*gam^(1/3);
% y0 = [tgam3+Theta10*gam;
%       alpha*tgam3+(alpha*Theta10+c1)*gam;
%       2*(tgam3+Theta10*gam);
%       (alpha*tgam3+(alpha*Theta10+c1)*gam)*(1-cos(2*(tgam3+Theta10*gam)))];

% Perturb STABLE ICs for experimentation
% y0 = y0 + (1e-4)*randn(4,1);
  
% Simulate!
% y1: theta
% y2: thetadot
% y3: phi
% y4: phidot
Yminus = zeros(n,4);
Yplus = zeros(n,4);
for itor = 1:n
    
    % Perturb ICs - Lammert
    Yminus(itor,:) = y0 + c*randn(4,1);
    
    %%% Perturb ICs - Garcia
    %temp = zeros(4,1);
    %temp(floor(rand(1,1)*4+1)) = sign(randn(1,1));
    %Yminus(itor,:) = y0 + c*temp;
    
    % Run simulation
    y = simpwm_noviz(gam,steps,Yminus(itor,:)');
        
    % Calculate heelstrike
    c2y1 = cos(2*y(end,1)); % Calculate once for new ICs
    yplus = [-y(end,1);
        c2y1*y(end,2);
        -2*y(end,1);
        c2y1*(1-c2y1)*y(end,2)]; % Mapping to calculate new ICs after collision
    
    % Store Result
    Yplus(itor,:) = yplus;
end

% Eliminate solutions with no movement
% NOTE: Need to get to the bottom of why those solutions exist!
ind = Yplus(:,1)>0;
Yplus = Yplus(ind,:);
Yminus = Yminus(ind,:);
n = size(Yplus,1);

% % % % Jacobian Estimation - Partial State
% % % % J is a 2-by-2 matrix of partial derivatives
% % % % rows represent state displacements after heelstrike
% % % % columns represent state displacements before heelstrike
% % % J = zeros(2,2);
% % % b = regress(Yplus(:,1),[Yminus(:,[1 2]) ones(n,1)]);
% % % J(1,:) = b(1:2);
% % % b = regress(Yplus(:,2),[Yminus(:,[1 2]) ones(n,1)]);
% % % J(2,:) = b(1:2);

% Jacobian Estimation - Full State
% J is a 4-by-4 matrix of partial derivatives
% rows represent state variables after heelstrike
% columns represent state variables before heelstrike
J = zeros(4,4);
b = regress(Yplus(:,1),[Yminus ones(n,1)]);
J(1,:) = b(1:4);
b = regress(Yplus(:,2),[Yminus ones(n,1)]);
J(2,:) = b(1:4);
b = regress(Yplus(:,3),[Yminus ones(n,1)]);
J(3,:) = b(1:4);
b = regress(Yplus(:,4),[Yminus ones(n,1)]);
J(4,:) = b(1:4);

% disp('Jacobian (Numerical):');
J(1:2,1:2);

% disp('Jacobian (Analytical):');
if strcmp(period,'short')
    % Analytical Jacobian - short period
    Jan = [7.2959766 5.7743697; -5.7743697 -4.2959766] - [17.2297481 17.8663823; 21.0696840 12.0844905].*gam^(2/3);
elseif strcmp(period,'long')
    % Analytical Jacobian - long period
    Jan = [-5.0707519 -5.8082044; 5.8082044 6.5570116] - [20.3741653 22.1941780; 13.2143569 15.7150640].*gam^(2/3);
else
    error('period must be specified as short or long')
end

% Eigenvalue Decomposition - numerical
[V D] = eigs(J);
% disp('Magnitude of Eigenvalues (Numerical, 4x4):')
abs(diag(D)');

% Eigenvalue Decomposition - numerical
[V D] = eigs(J(1:2,1:2));
% disp('Magnitude of Eigenvalues (Numerical, 2x2):')
e_n = abs(diag(D)');

% Eigenvalue Decomposition - analytical
[V D] = eigs(Jan);
% disp('Magnitude of Eigenvalues (Analytical):')
e_a = abs(real(diag(D)'));

if gam < 0.015
    if e_a(1) > 1 || e_a(2) > 1
        stable = 1;
    end
else 
    if e_n(1) > 1 || e_n(2) > 1
        stable = 1;
    end
end

%eof