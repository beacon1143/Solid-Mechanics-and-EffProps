clear

loadValue = 0.00075;
nGrid = 7;
nTimeSteps = 200;
nIter = 500;

%Sxx = get_sigma_2D(loadValue, [1, 0, 0], nGrid, nTimeSteps, nIter);
%Syy = get_sigma_2D(loadValue, [0, 1, 0], nGrid, nTimeSteps, nIter);
%Sxy = get_sigma_2D(loadValue, [0, 0, 1], nGrid, nTimeSteps, nIter);

%C1111 = zeros(nTimeSteps, 1);
%C1122 = zeros(nTimeSteps, 1);
%C1112 = zeros(nTimeSteps, 1);
%C2222 = zeros(nTimeSteps, 1);
%C1222 = zeros(nTimeSteps, 1);
%C1212 = zeros(nTimeSteps, 1);

%for it = 1:nTimeSteps
%  C1111(it) = Sxx(it, 1) / loadValue / it * nTimeSteps
%  C1122(it) = Sxx(it, 2) / loadValue / it * nTimeSteps
%  C1112(it) = Sxx(it, 3) / loadValue / it * nTimeSteps
%
%  C2222(it) = Syy(it, 2) / loadValue / it * nTimeSteps
%  C1222(it) = Syy(it, 3) / loadValue / it * nTimeSteps

%  C1212(it) = Sxy(it, 3) / loadValue / it * nTimeSteps
%endfor

%% POSTPROCESSING
%subplot(2, 2, 1)
%plot(1:nTimeSteps, C1111), title("C_{1111}")
%subplot(2, 2, 2)
%plot(1:nTimeSteps, C1122), title("C_{1122}")
%subplot(2, 2, 3)
%plot(1:nTimeSteps, C2222), title("C_{2222}")
%subplot(2, 2, 4)
%plot(1:nTimeSteps, C1212), title("C_{1212}")
%drawnow

% GPU CALCULATION
system(['nvcc -DNGRID=', int2str(nGrid), ' -DNT=', int2str(nTimeSteps), ' -DNITER=', int2str(nIter), ' -DNPARS=', int2str(9), ' boundary_problem.cu']);
system(['.\a.exe']);

%% POSTPROCESSING
%subplot(2, 2, 1)
%plot(1:nTimeSteps, C1111), title("C_{1111}")
%subplot(2, 2, 2)
%plot(1:nTimeSteps, C1122), title("C_{1122}")
%subplot(2, 2, 3)
%plot(1:nTimeSteps, C2222), title("C_{2222}")
%subplot(2, 2, 4)
%plot(1:nTimeSteps, C1212), title("C_{1212}")
%drawnow


Sxx = get_sigma_2D(loadValue, [1, 1, 0], nTimeSteps) / loadValue
