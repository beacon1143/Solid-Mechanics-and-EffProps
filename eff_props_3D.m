clear
figure(1)
clf
colormap jet

% PHYSICS
Lx  = 20.0;                         % physical length
Ly  = 20.0;                         % physical width
Lz  = 20.0;                         % physical height
initLoadValue = -0.00004;
loadType = [1.0, 1.0, 1.0, 0.0, 0.0, 0.0];
Y = 0.00001;
nPores = 1;
porosity = 0.005;
rad = (0.75 * porosity * Lx * Ly * Lz / (pi * nPores ^ 3)) ^ (1 / 3);
nTasks = 2;

% NUMERICS
nGrid = 2;
nTimeSteps = 1;
nIter = 1000;
eIter = 1.0e-6;
iDevice = 0;

needCPUcalculation = true;

Nx  = 8 * nGrid;     % number of space steps
Ny  = 8 * nGrid;
Nz  = 8 * nGrid;

get_sigma_3D(Lx, Ly, Lz, initLoadValue, loadType, nGrid, nTimeSteps, nIter, eIter, nPores, Y, porosity, needCPUcalculation);

% GPU CALCULATION
outname = ['a', int2str(iDevice)];
system(['nvcc -O 3 -allow-unsupported-compiler -o ', outname, ' -DDEVICE_IDX=', int2str(iDevice), ' -DNL=', int2str(nTasks), ' -DNGRID=', int2str(nGrid), ' -DNITER=', int2str(nIter), ' -DEITER=', num2str(eIter), ' -DNPARS=', int2str(13), ' EffPlast3D.cu main3D.cu']);
system(['.\', outname, '.exe ', num2str(initLoadValue), ' ', num2str(loadType(1)), ' ', num2str(loadType(2)), ' ', num2str(loadType(3)), ' ', num2str(loadType(4)), ' ', num2str(loadType(5)), ' ', num2str(loadType(6)), ' ', num2str(nTimeSteps)]); %, ' ' num2str(addLoadValueStep)]);

if not(needCPUcalculation)
  
else % needCPUcalculation
  PmXY = read_data_2D('data\PmXY', Nx, Nx, Ny);
  PmXZ = read_data_2D('data\PmXZ', Nx, Nx, Ny);
  PmYZ = read_data_2D('data\PmYZ', Nx, Nx, Ny);
  tauXXm = read_data_2D('data\tauXXm', Nx, Nx, Ny);
  tauYYm = read_data_2D('data\tauYYm', Nx, Nx, Ny);
  tauXZmXY = read_data_2D('data\tauXZmXY', Nx, Nx - 1, Ny);
  UxmXY = read_data_2D('data\UxmXY', Nx, Nx + 1, Ny);
  VxmXY = read_data_2D('data\VxmXY', Nx, Nx + 1, Ny);
  
  PcXY = read_data_2D('data\PcXY', Nx, Nx, Ny);
  tauXZcXY = read_data_2D('data\tauXZcXY', Nx, Nx - 1, Ny);
  UxcXY = read_data_2D('data\UxcXY', Nx, Nx + 1, Ny);
  VxcXY = read_data_2D('data\VxcXY', Nx, Nx + 1, Ny);
  
  diffPxy = PmXY - PcXY;
  difftauXZxy = tauXZmXY - tauXZcXY;
  diffUxXY = UxmXY - UxcXY;
  diffVxXY = VxmXY - VxcXY;
  
  % POSTPROCESSING
  subplot(2, 3, 1)
  imagesc(PmXY)
  colorbar
  title('PmXY')
  axis image
  
  subplot(2, 3, 2)
  imagesc(PcXY)
  colorbar
  title('PcXY')
  axis image
  
  subplot(2, 3, 3)
  imagesc(diffPxy)
  colorbar
  title('diffPxy')
  axis image
  
  %subplot(2, 3, 1)
  %imagesc(tauXZmXY)
  %colorbar
  %title('tauXZmXY')
  %axis image
  
  %subplot(2, 3, 2)
  %imagesc(tauXZcXY)
  %colorbar
  %title('tauXZcXY')
  %axis image
  
  %subplot(2, 3, 3)
  %imagesc(difftauXZxy)
  %colorbar
  %title('difftauXZxy')
  %axis image
  
  subplot(2, 3, 4)
  imagesc(UxmXY)
  colorbar
  title('UxmXY')
  axis image
  
  subplot(2, 3, 5)
  imagesc(UxcXY)
  colorbar
  title('UxcXY')
  axis image
  
  subplot(2, 3, 6)
  imagesc(diffUxXY)
  colorbar
  title('diffUxXY')
  axis image
  
  %subplot(2, 2, 2)
  %imagesc(tauXXm)
  %colorbar
  %title('tauXXm')
  %axis image
  
  %subplot(2, 2, 3)
  %imagesc(tauYYm)
  %colorbar
  %title('tauYYm')
  %axis image
  
  %subplot(2, 2, 4)
  %imagesc(tauXYm)
  %colorbar
  %title('tauXYm')
  %axis image
  
  drawnow
end % if(needCPUcalculation)