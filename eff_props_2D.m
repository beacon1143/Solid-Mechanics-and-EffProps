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
  fil = fopen('Pm.dat', 'rb');
  Pm = fread(fil, 'double');
  fclose(fil);
  Pm = reshape(Pm, Nx, Ny);

  diffP = Pm - Pc;
  
  fil = fopen('tauXXm.dat', 'rb');
  tauXXm = fread(fil, 'double');
  fclose(fil);
  tauXXm = reshape(tauXXm, Nx, Ny);

  diffTauXX = tauXXm - tauXXc;
  
  fil = fopen('tauYYm.dat', 'rb');
  tauYYm = fread(fil, 'double');
  fclose(fil);
  tauYYm = reshape(tauYYm, Nx, Ny);

  diffTauYY = tauYYm - tauYYc;

  fil = fopen('tauXYm.dat', 'rb');
  tauXYm = fread(fil, 'double');
  fclose(fil);
  tauXYm = reshape(tauXYm, Nx - 1, Ny - 1);

  diffTauXY = tauXYm - tauXYc;

  fil = fopen('tauXYavm.dat', 'rb');
  tauXYavm = fread(fil, 'double');
  fclose(fil);
  tauXYavm = reshape(tauXYavm, Nx, Ny);

  diffTauXYav = tauXYavm - tauXYavc;

  fil = fopen('J2m.dat', 'rb');
  J2m = fread(fil, 'double');
  fclose(fil);
  J2m = reshape(J2m, Nx, Ny);

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
    cd data
    
    fil = fopen(strcat('UnuAbs_', int2str(Nx), '_.dat'), 'rb');
    UnuAbs = fread(fil, 'double');
    fclose(fil);
    UnuAbs = reshape(UnuAbs, Nx, Ny);
    UnuAbs = UnuAbs ./ rad;

    fil = fopen(strcat('J1nu_', int2str(Nx), '_.dat'), 'rb');
    J1nu = fread(fil, 'double');
    fclose(fil);
    J1nu = reshape(J1nu, Nx - 1, Ny - 1);
    J1nu = J1nu ./ Y;
    
    fil = fopen(strcat('J2nu_', int2str(Nx), '_.dat'), 'rb');
    J2nu = fread(fil, 'double');
    fclose(fil);
    J2nu = reshape(J2nu, Nx - 1, Ny - 1);
    J2nu = J2nu ./ (2.0 * Y * Y);

    fil = fopen(strcat('plast_nu_', int2str(Nx), '_.dat'), 'rb');
    plast_nu = fread(fil, 'double');
    fclose(fil);
    plast_nu = reshape(plast_nu, Nx - 1, Ny - 1);
    
    fil = fopen(strcat('tauXYc_', int2str(Nx), '_.dat'), 'rb');
    tauXYc = fread(fil, 'double');
    fclose(fil);
    tauXYc = reshape(tauXYc, Nx - 1, Ny - 1);
    tauXYc = transpose(tauXYc);

    fil = fopen(strcat('tauXYavc_', int2str(Nx), '_.dat'), 'rb');
    tauXYavc = fread(fil, 'double');
    fclose(fil);
    tauXYavc = reshape(tauXYavc, Nx, Ny);
    tauXYavc = transpose(tauXYavc);
    
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
    
    %subplot(3, 4, 3)
    %imagesc(plast_nu)
    %colorbar
    %title('plast zone numerical')
    %axis image
    %set(gca, 'FontSize', 10)

    subplot(3, 3, 3)
    imagesc(UnuAbs)
    colorbar
    title('|u|/R numerical')
    axis image
    set(gca, 'FontSize', 10, 'fontWeight', 'bold')
    
    if nPores == 1
      fil = fopen(strcat('UanAbs_', int2str(Nx), '_.dat'), 'rb');
      UanAbs = fread(fil, 'double');
      fclose(fil);
      UanAbs = reshape(UanAbs, Nx, Ny);
      UanAbs = UanAbs ./ rad;
      
      fil = fopen(strcat('errorUabs_', int2str(Nx), '_.dat'), 'rb');
      errorUabs = fread(fil, 'double');
      fclose(fil);
      errorUabs = reshape(errorUabs, Nx, Ny);
      errorUabs = 100 * errorUabs;
      
      fil = fopen(strcat('J1an_', int2str(Nx), '_.dat'), 'rb');
      J1an = fread(fil, 'double');
      fclose(fil);
      J1an = reshape(J1an, Nx - 1, Ny - 1);
      J1an = J1an ./ Y;
      
      fil = fopen(strcat('J2an_', int2str(Nx), '_.dat'), 'rb');
      J2an = fread(fil, 'double');
      fclose(fil);
      J2an = reshape(J2an, Nx - 1, Ny - 1);
      J2an = J2an ./ (2.0 * Y * Y);
      
      fil = fopen(strcat('errorJ1_', int2str(Nx), '_.dat'), 'rb');
      errorJ1 = fread(fil, 'double');
      fclose(fil);
      errorJ1 = reshape(errorJ1, Nx - 1, Ny - 1);
      errorJ1 = 100 * errorJ1;
      
      fil = fopen(strcat('errorJ2_', int2str(Nx), '_.dat'), 'rb');
      errorJ2 = fread(fil, 'double');
      fclose(fil);
      errorJ2 = reshape(errorJ2, Nx - 1, Ny - 1);
      errorJ2 = 100 * errorJ2;
      
      fil = fopen(strcat('plast_an_', int2str(Nx), '_.dat'), 'rb');
      plast_an = fread(fil, 'double');
      fclose(fil);
      plast_an = reshape(plast_an, Nx - 1, Ny - 1);
      
      plastDiff = abs(plast_an - plast_nu);

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
  
      %subplot(3, 4, 7)
      %imagesc(plast_an)
      %colorbar
      %title('plast zone analytics')
      %axis image
      %set(gca, 'FontSize', 10)
      
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
  
      %subplot(3, 4, 11)
      %imagesc(plastDiff)
      %colorbar
      %title('plast zone diff')
      %axis image
      %set(gca, 'FontSize', 10)
      
      subplot(3, 3, 9)
      imagesc(errorUabs)
      colorbar
      title('|u| error, %')
      axis image
      set(gca, 'FontSize', 10, 'fontWeight', 'bold')
    end %if (N == 1)
    
    cd ..
    
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

