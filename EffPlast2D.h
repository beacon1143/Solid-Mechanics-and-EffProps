#include <iostream>
#include <stdexcept>
#include <fstream>
#include <vector>
#include <string>
#include <array>
#include <set>
#include <limits>
#include <algorithm>
#include <complex>
#include <chrono>

#include <cuda_runtime.h>
#include <device_launch_parameters.h>

#if !defined(NGRID)
#define NGRID 32
#endif

#if !defined(NPARS)
#define NPARS 11
#endif

#if !defined(NL)
#define NL 3
#endif

#if !defined(NITER)
#define NITER 100'000
#endif

#if !defined(EITER)
#define EITER 1.0e-10
#endif

#if !defined(DEVICE_IDX)
#define DEVICE_IDX 0
#endif

#define gpuErrchk(ans) { gpuAssert((ans), __FILE__, __LINE__); }
inline void gpuAssert(cudaError_t code, const char* file, int line)
{
	if (code != cudaSuccess)
	{
		std::cout << "[" + std::string(file) + ":" + std::to_string(line) + "] " + "CUDA error: " + std::string(cudaGetErrorString(code));
		exit(-1);
	}
}

#define gpuGetLastError() gpuErrchk(cudaGetLastError())

class EffPlast2D {
public:
	double EffPlast2D::ComputeEffModuli( double initLoadValue, double loadValue, 
		unsigned int nTimeSteps, const std::array<double, 3>& loadType
	);

	EffPlast2D();
	~EffPlast2D();
private:
	dim3 grid, block;
	long int nX, nY;

	// input parameters
	double* pa_cuda, * pa_cpu;
	double dX, dY, dT;
	double rad;                                      // radius of hole
	double K0, G0;                                   // bulk modulus and shear modulus
	double E0, nu0;                                  // Young's modulus and Poisson's ratio
	double Y;                                        // yield stress
	double nPores;

	// input variables
	unsigned int nTimeSteps_;                        // number of time steps for preloading static calculation
	std::array<double, 3> loadType_;                 // load type array: ratio between effective strains

	// space arrays
	double* K_cpu, * K_cuda, * G_cpu, * G_cuda;      // materials
	double* P0_cpu, * P0_cuda, * P_cpu, * P_cuda;    // stress
	double* tauXX_cpu, * tauXX_cuda;
	double* tauYY_cpu, * tauYY_cuda;
	double* tauXY_cpu, * tauXY_cuda;
	double* tauXYav_cpu, * tauXYav_cuda;
	double* J2_cpu, * J2_cuda;                       // plasticity
	double* J2XY_cpu, * J2XY_cuda;
	double* Ux_cpu, * Ux_cuda;                       // displacement
	double* Uy_cpu, * Uy_cuda;
	double* Vx_cpu, * Vx_cpu_old, * Vx_cuda;                       // velocity
	double* Vxdt_cpu, * Vxdt_cuda;
	double* Vy_cpu, * Vy_cpu_old, * Vy_cuda;
	double* Vydt_cpu, * Vydt_cuda;

	// utilities
	std::ofstream log_file;
	size_t output_step;
	double lX, lY;
	double porosity;
	std::set<std::pair<int, int>> empty_spaces;
	const double incPercent = 0.005;    // for calculation of effective moduli with plasticity

	// output parameters
	std::array<std::vector<double>, NL> deltaP;
	std::array<std::vector<double>, NL> deltaPper;
	std::array<std::vector<double>, NL> tauInfty;
	std::array<std::vector<double>, NL> dPhi;
	std::array<std::vector<double>, NL> dPhiPer;
	std::array<double, 3> curEffStrain;
	std::array<std::vector<std::array<double, 3>>, NL> epsilon;
	std::array<std::vector<std::array<double, 3>>, NL> epsilonPer;
	std::array<std::vector<std::array<double, 4>>, NL> sigma;    // sigma_zz is non-zero due to plane strain
	std::array<std::vector<std::array<double, 4>>, NL> sigmaPer;

	// effective moduli
	struct EffModuli {
		double Kphi;
		double Kd;
		double G;
		void output(std::ofstream& log_file) {
			std::cout << "        Kphi = " << Kphi << "\n";
			log_file << "        Kphi = " << Kphi << "\n";
			std::cout << "        Kd = " << Kd << "\n";
			log_file << "        Kd = " << Kd << "\n";
			if (NL > 2) {
				std::cout << "        G = " << G << "\n";
				log_file << "        G = " << G << "\n";
			}
		}
	};
	EffModuli eff_moduli_an,
						eff_moduli_an_per,
						eff_moduli_num,
						eff_moduli_num_per;

	void ComputeEffParams(const size_t step, const double loadStepValue, const std::array<double, 3>& loadType, const size_t nTimeSteps);

	void ReadParams(const std::string& filename);
	void SetMaterials();
	void SetInitPressure(const double coh);

	static void SetMatrixZero(double** A_cpu, double** A_cuda, const int m, const int n);
	static void SaveMatrix(double* const A_cpu, const double* const A_cuda, const int m, const int n, const std::string& filename);
	static void SaveVector(double* const arr, const int size, const std::string& filename);

	static double FindMaxAbs(const double* const arr, const int size);
	static double FindMaxAbs(const std::vector<double>& vec);

	// p and tau from static numeric solution for analytical effective moduli 
	double getDeltaP_honest();
	double getDeltaP_periodic();
	double getDeltaP_approx(const double Exx, const double Eyy);
	double getTauInfty_honestest();
	double getTauInfty_honest();
	double getTauInfty_approx(const double Exx, const double Eyy);
	[[deprecated]] double getdPhi();

	// analytic solution for static problem
	void getAnalytic(
		double x, double y, double xi, double kappa, double c0,
		double& cosf, double& sinf,
		std::complex<double>& zeta, std::complex<double>& w,
		std::complex<double>& dw, std::complex<double>& wv,
		std::complex<double>& Phi, std::complex<double>& Psi
	);
	std::complex<double> getAnalyticUelast(double x, double y, double tauInfty, double xi, double kappa, double c0);
	double getAnalyticUrHydro(double r, double deltaP);
	double getJ1(double S11, double S22);
	double getJ2(double S11, double S22, double S12);
	void getAnalyticJelast(double x, double y, double xi, double kappa, double c0, double& J1, double& J2);
	void getAnalyticJplast(double r, double xi, double& J1, double& J2);
	void SaveAnStatic2D(const double deltaP, const double tauInfty);

	// console and log file output
	void printStepInfo(const size_t step);
	void printCalculationType();
	void printEffectiveModuli();
	void printWarnings();
	void printDuration(int elapsed_sec);

	// final effective moduli calculation
	void calcBulkModuli_PureElast();
	void calcBulkModuli_ElastPlast();
	void calcShearModulus();
	double getKphi_PureElast();
	double getKphiPer_PureElast();
	double getKd_PureElast();
	double getKdPer_PureElast();
	double getKphi_ElastPlast();
	double getKphiPer_ElastPlast();
	double getKd_ElastPlast();
	double getKdPer_ElastPlast();
	double getG();
	double getGper();
};