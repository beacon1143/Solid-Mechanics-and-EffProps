clear
figure(1)
clf
colormap jet

% PHYSICS
Lx  = 20.0;                         % physical length
Ly  = 20.0;                         % physical width
initLoadValue = -0.000015;
addLoadValueStep = -0.000025;
loadType = [4.0, -2.0, 0.0];
Y = 0.00001;
nPores = 1;
porosity = 0.005;
rad = sqrt(porosity * Lx * Ly / (pi * nPores * nPores));
nTasks = 3;

% NUMERICS
nGrid = 64;
nTimeSteps = 1;
nIter = 5000000;
eIter = 1.0e-9;
device = 0;

needCPUcalculation = false;
needCompareStatic = true;
if nPores > 1
  needCompareStatic = false;
end %if
needPeriodicBCs = true;
if nPores < 3
  needPeriodisBCs = false;
end %if

Nx  = 32 * nGrid;     % number of space steps
Ny  = 32 * nGrid;

Sxx = get_sigma_2D(Lx, Ly, initLoadValue, loadType, nGrid, nTimeSteps, nIter, eIter, nPores, Y, porosity, needCPUcalculation);

% GPU CALCULATION
outname = ['a', int2str(device)];
system(['nvcc -O 3 -allow-unsupported-compiler -o ', outname, ' -DDEVICE_IDX=', int2str(device), ' -DNL=', int2str(nTasks), ' -DNGRID=', int2str(nGrid), ' -DNITER=', int2str(nIter), ' -DEITER=', num2str(eIter), ' -DNPARS=', int2str(11), ' EffPlast2D.cu main.cu'])
system(['.\', outname, '.exe ', num2str(initLoadValue), ' ', num2str(loadType(1)), ' ', num2str(loadType(2)), ' ', num2str(loadType(3)), ' ', num2str(nTimeSteps), ' ' num2str(addLoadValueStep)])

Pc = read_data_2D('data\Pc', Nx, Nx, Ny);
tauXXc = read_data_2D('data\tauXXc', Nx, Nx, Ny);
tauYYc = read_data_2D('data\tauYYc', Nx, Nx, Ny);
J2c = read_data_2D('data\J2c', Nx, Nx, Ny);
Uxc = read_data_2D('data\Uxc', Nx, Nx + 1, Ny);
Uyc = read_data_2D('data\Uyc', Nx, Nx, Ny + 1);
%Ur = sqrt(Ux(1:end-1,:) .* Ux(1:end-1,:) + Uy(:,1:end-1) .* Uy(:,1:end-1))

if needCPUcalculation
  Pm = read_data_2D('data\Pm', Nx, Nx, Ny);
  tauXXm = read_data_2D('data\tauXXm', Nx, Nx, Ny);
  tauYYm = read_data_2D('data\tauYYm', Nx, Nx, Ny);
  tauXYm = read_data_2D('data\tauXYm', Nx, Nx - 1, Ny - 1);
  tauXYavm = read_data_2D('data\tauXYavm', Nx, Nx, Ny);
  J2m = read_data_2D('data\J2m', Nx, Nx, Ny);
  
  diffP = Pm - Pc;
  diffTauXX = tauXXm - tauXXc;
  diffTauYY = tauYYm - tauYYc;
  diffTauXY = tauXYm - tauXYc;
  diffTauXYav = tauXYavm - tauXYavc;
  diffJ2 = J2c - J2m;

  % POSTPROCESSING
  subplot(2, 2, 1)
  imagesc(Pm)
  colorbar
  title('Pm')
  axis image

  subplot(2, 2, 3)
  imagesc(diffP)
  colorbar
  title('diffP')
  axis image

  subplot(2, 2, 2)
  imagesc(tauXXm)
  colorbar
  title('tauXXm')
  axis image

  subplot(2, 2, 4)
  imagesc(diffTauYY)
  colorbar
  title('diffTauYY')
  axis image

  drawnow
else
  % POSTPROCESSING
  if needCompareStatic
    % ANALYTIC SOLUTION FOR STATICS
    %cd data
    
    UnuAbs = read_data_2D('data\UnuAbs', Nx, Nx, Ny);
    UnuAbs = UnuAbs ./ rad;

    J1nu = read_data_2D('data\J1nu', Nx, Nx - 1, Ny - 1);
    J1nu = J1nu ./ Y;
    
    J2nu = read_data_2D('data\J2nu', Nx, Nx - 1, Ny - 1);
    J2nu = J2nu ./ (2.0 * Y * Y);

    %plast_nu = read_data_2D('data\plast_nu', Nx, Nx - 1, Ny - 1);    
    tauXYc = read_data_2D('data\tauXYc', Nx, Nx - 1, Ny - 1);
    tauXYavc = read_data_2D('data\tauXYavc', Nx, Nx, Ny);
    
    subplot(3, 3, 1)
    imagesc(J1nu)
    colorbar
    title('J_1/Y numerical')
    axis image
    set(gca, 'FontSize', 10, 'fontWeight', 'bold')
    
    subplot(3, 3, 2)
    imagesc(J2nu)
    colorbar
    title('J_2/Y^2 numerical')
    axis image
    set(gca, 'FontSize', 10, 'fontWeight', 'bold')

    subplot(3, 3, 3)
    imagesc(UnuAbs)
    colorbar
    title('|u|/R numerical')
    axis image
    set(gca, 'FontSize', 10, 'fontWeight', 'bold')
    
    if nPores == 1
      UanAbs = read_data_2D('data\UanAbs', Nx, Nx, Ny);
      UanAbs = UanAbs ./ rad;
      
      errorUabs = read_data_2D('data\errorUabs', Nx, Nx, Ny);
      errorUabs = 100 * errorUabs;
      
      J1an = read_data_2D('data\J1an', Nx, Nx - 1, Ny - 1);
      J1an = J1an ./ Y;
      
      J2an = read_data_2D('data\J2an', Nx, Nx - 1, Ny - 1);
      J2an = J2an ./ (2.0 * Y * Y);
      
      errorJ1 = read_data_2D('data\errorJ1', Nx, Nx - 1, Ny - 1);
      errorJ1 = 100 * errorJ1;
      
      errorJ2 = read_data_2D('data\errorJ2', Nx, Nx - 1, Ny - 1);
      errorJ2 = 100 * errorJ2;
      
      %plast_an = read_data_2D('data\plast_an', Nx, Nx - 1, Ny - 1);      
      %plastDiff = abs(plast_an - plast_nu);

      subplot(3, 3, 4)
      imagesc(J1an)
      colorbar
      title('J_1/Y analytic')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
      
      subplot(3, 3, 5)
      imagesc(J2an)
      colorbar
      title('J_2/Y^2 analytic')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
      
      subplot(3, 3, 6)
      imagesc(UanAbs)
      colorbar
      title('|u|/R analytic')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
  
      subplot(3, 3, 7)
      imagesc(errorJ1)
      colorbar
      title('J_1 error, %')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
      
      subplot(3, 3, 8)
      imagesc(errorJ2)
      colorbar
      title('J_2 error, %')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
      
      subplot(3, 3, 9)
      imagesc(errorUabs)
      colorbar
      title('|u| error, %')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
    end %if (N == 1)
    
    drawnow
  else  
    subplot(2, 3, 1)
    if needPeriodicBCs
      imagesc(Pc(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(Pc(2:end-1, 2:end-1))
    end
    colorbar
    title('P')
    axis image

    subplot(2, 3, 5)
    if needPeriodicBCs
      imagesc(tauXXc(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(tauXXc(2:end-1, 2:end-1))
    end
    colorbar
    title('tauXX')
    axis image

    subplot(2, 3, 2)
    if needPeriodicBCs
      imagesc(J2c(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(J2c(2:end-1, 2:end-1))
    end
    colorbar
    title('J2')
    axis image

    subplot(2, 3, 4)
    if needPeriodicBCs
      imagesc(tauYYc(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(tauYYc(2:end-1, 2:end-1))
    end
    colorbar
    title('tauYY')
    axis image
    
    subplot(2, 3, 3)
    if needPeriodicBCs
      imagesc(Uxc(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(Uxc)
    end
    colorbar
    title('Ux')
    axis image
    
    subplot(2, 3, 6)
    if needPeriodicBCs
      imagesc(Uyc(int32(end / nPores) : int32(end * (nPores - 1)/ nPores), int32(end / nPores) : int32(end * (nPores - 1)/ nPores)))
    else
      imagesc(Uyc)
    end
    colorbar
    title('Uy')
    axis image

    drawnow
  end %if (needCompareStatic)
end %if (needCPUcalculation)

