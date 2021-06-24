clear
figure(1)
clf
colormap jet

loadValue = -0.002;
nGrid = 24;
nTimeSteps = 1;
nIter = 1000000;
eIter = 1.0e-10;
needCPUcalculation = false;
needCompareStatic = true;

Nx  = 32 * nGrid;     % number of space steps
Ny  = 32 * nGrid;

Sxx = get_sigma_2D(loadValue, [1.0, 1.0, 0], nGrid, nTimeSteps, nIter, eIter, needCPUcalculation);

% GPU CALCULATION
system(['nvcc -DNGRID=', int2str(nGrid), ' -DNT=', int2str(nTimeSteps), ' -DNITER=', int2str(nIter), ' -DEITER=', num2str(eIter), ' -DNPARS=', int2str(12), ' EffPlast2D.cu main.cu']);
system(['.\a.exe']);

fil = fopen(strcat('Pc_', int2str(Nx), '_.dat'), 'rb');
Pc = fread(fil, 'double');
fclose(fil);
Pc = reshape(Pc, Nx, Ny);

fil = fopen(strcat('tauXXc_', int2str(Nx), '_.dat'), 'rb');
tauXXc = fread(fil, 'double');
fclose(fil);
tauXXc = reshape(tauXXc, Nx, Ny);

fil = fopen(strcat('tauYYc_', int2str(Nx), '_.dat'), 'rb');
tauYYc = fread(fil, 'double');
fclose(fil);
tauYYc = reshape(tauYYc, Nx, Ny);

fil = fopen(strcat('tauXYc_', int2str(Nx), '_.dat'), 'rb');
tauXYc = fread(fil, 'double');
fclose(fil);
tauXYc = reshape(tauXYc, Nx - 1, Ny - 1);

fil = fopen(strcat('tauXYavc_', int2str(Nx), '_.dat'), 'rb');
tauXYavc = fread(fil, 'double');
fclose(fil);
tauXYavc = reshape(tauXYavc, Nx, Ny);

fil = fopen(strcat('J2c_', int2str(Nx), '_.dat'), 'rb');
J2c = fread(fil, 'double');
fclose(fil);
J2c = reshape(J2c, Nx, Ny);

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
  imagesc(diffTauXX)
  colorbar
  title('diffTauXX')
  axis image

  drawnow
else
  % POSTPROCESSING
  if needCompareStatic
    % ANALYTIC SOLUTION FOR STATICS
    fil = fopen(strcat('xxx_', int2str(Nx), '_.dat'), 'rb');
    xxx = fread(fil, 'double');
    fclose(fil);
    xxx = reshape(xxx, Nx, 1);

    fil = fopen(strcat('Sanrr_', int2str(Nx), '_.dat'), 'rb');
    Sanrr = fread(fil, 'double');
    fclose(fil);
    Sanrr = reshape(Sanrr, Nx, 1);
    
    fil = fopen(strcat('Sanff_', int2str(Nx), '_.dat'), 'rb');
    Sanff = fread(fil, 'double');
    fclose(fil);
    Sanff = reshape(Sanff, Nx, 1);

    fil = fopen(strcat('Snurr_', int2str(Nx), '_.dat'), 'rb');
    Snurr = fread(fil, 'double');
    fclose(fil);
    Snurr = reshape(Snurr, Nx, 1);
    
    fil = fopen(strcat('Snuff_', int2str(Nx), '_.dat'), 'rb');
    Snuff = fread(fil, 'double');
    fclose(fil);
    Snuff = reshape(Snuff, Nx, 1);
    
    subplot(1, 2, 1)
    plot(xxx(Nx/2 + 1:Nx), Sanrr(Nx/2 + 1:Nx), 'LineWidth' , 2, 'g', xxx(Nx/2 + 1:Nx), Snurr(Nx/2 + 1:Nx), 'LineWidth', 2, 'r') 
    title('\sigma_{rr}')
    xlabel('r')
    set(gca, 'FontSize', 15, 'fontWeight', 'bold')
    %set(findall(gcf,'type','text'),'FontSize',30,'fontWeight','bold')
    
    subplot(1, 2, 2)
    plot(xxx(Nx/2 + 1:Nx), Sanff(Nx/2 + 1:Nx), 'LineWidth' , 2, 'g', xxx(Nx/2 + 1:Nx), Snuff(Nx/2 + 1:Nx), 'LineWidth' , 2, 'r') 
    title('\sigma_{\phi \phi}')
    xlabel('r')
    set(gca, 'FontSize', 15, 'fontWeight', 'bold')
    
    drawnow
  else  
    subplot(2, 2, 1)
    imagesc(Pc(2:end-1, 2:end-1))
    colorbar
    title('P')
    axis image

    subplot(2, 2, 3)
    imagesc(tauXXc(2:end-1, 2:end-1))
    colorbar
    title('tauXX')
    axis image

    subplot(2, 2, 2)
    imagesc(J2c(2:end-1, 2:end-1))
    colorbar
    title('J2')
    axis image

    subplot(2, 2, 4)
    imagesc(tauYYc(2:end-1, 2:end-1))
    colorbar
    title('tauYY')
    axis image

    drawnow
  end %if (needCompareStatic)
end %if (needCPUcalculation)