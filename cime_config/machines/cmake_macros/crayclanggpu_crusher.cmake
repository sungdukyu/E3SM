if (compile_threaded)
  string(APPEND FFLAGS   " -fopenmp")
  string(APPEND CFLAGS   " -fopenmp")
  string(APPEND CXXFLAGS " -fopenmp")
  string(APPEND LDFLAGS  " -fopenmp")
endif()
if (DEBUG)
  string(APPEND CFLAGS   " -O0 -g")
  string(APPEND FFLAGS   " -O0 -g")
  string(APPEND CXXFLAGS " -O0 -g")
  string(APPEND CPPDEFS " -DYAKL_DEBUG")
endif()
string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_R16 -DCPRCRAY")
string(APPEND FC_AUTO_R8 " -s real64")
string(APPEND FFLAGS " -f free -N 255 -h byteswapio -em")
if (NOT compile_threaded)
  string(APPEND FFLAGS " -M1077")
endif()
string(APPEND FFLAGS_NOOPT " -O0")
set(HAS_F2008_CONTIGUOUS "TRUE")
string(APPEND LDFLAGS " -Wl,--allow-multiple-definition -h byteswapio")
set(SUPPORTS_CXX "TRUE")
set(CXX_LINKER "FORTRAN")
set(MPICC "cc")
set(MPICXX "CC")
set(MPIFC "ftn")
set(SCC "cc")
set(SCXX "CC")
set(SFC "ftn")

if (NOT DEBUG)
  string(APPEND CFLAGS   " -O2")
  string(APPEND CXXFLAGS " -O2")
  string(APPEND FFLAGS   " -O2")
  string(APPEND HIP_FLAGS " -O3 -munsafe-fp-atomics")
endif()
string(APPEND CFLAGS   " -I$ENV{MPICH_DIR}/include -I$ENV{ROCM_PATH}/include")
string(APPEND CXXFLAGS " -I$ENV{MPICH_DIR}/include -I$ENV{ROCM_PATH}/include")
string(APPEND FFLAGS   " -I$ENV{MPICH_DIR}/include -I$ENV{ROCM_PATH}/include")
string(APPEND HIP_FLAGS " -D__HIP_ROCclr__ -D__HIP_ARCH_GFX90A__=1 --rocm-path=$ENV{ROCM_PATH} --offload-arch=gfx90a -x hip")

if (COMP_NAME STREQUAL elm)
  string(APPEND FFLAGS " -hfp0")
endif()
string(APPEND FFLAGS " -hipa0 -hzero -em -ef")

string(APPEND SLIBS " -L$ENV{PNETCDF_PATH}/lib -lpnetcdf -L$ENV{ROCM_PATH}/lib -lamdhip64")
set(NETCDF_PATH "$ENV{NETCDF_DIR}")
set(PNETCDF_PATH "$ENV{PNETCDF_DIR}")
set(PIO_FILESYSTEM_HINTS "romio_cb_read=disable")
string(APPEND CXX_LIBS " -lstdc++")
set(USE_HIP "TRUE")
