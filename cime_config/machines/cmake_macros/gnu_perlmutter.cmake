string(APPEND CONFIG_ARGS " --host=cray")
if (COMP_NAME STREQUAL gptl)
  string(APPEND CPPDEFS " -DHAVE_NANOTIME -DBIT64 -DHAVE_SLASHPROC -DHAVE_GETTIMEOFDAY")
endif()
string(APPEND SLIBS " -L$ENV{CRAY_HDF5_PARALLEL_PREFIX}/lib -lhdf5_hl -lhdf5 -L$ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX} -L$ENV{CRAY_PARALLEL_NETCDF_PREFIX}/lib -lpnetcdf -lnetcdf -lnetcdff")
string(APPEND SLIBS " -lblas -llapack")
set(CXX_LINKER "FORTRAN")
set(NETCDF_PATH "$ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX}")
set(NETCDF_C_PATH "$ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX}")
set(NETCDF_FORTRAN_PATH "$ENV{CRAY_NETCDF_HDF5PARALLEL_PREFIX}")
set(HDF5_PATH "$ENV{CRAY_HDF5_PARALLEL_PREFIX}")
set(PNETCDF_PATH "$ENV{CRAY_PARALLEL_NETCDF_PREFIX}")
if (NOT DEBUG)
  string(APPEND CFLAGS " -O2 -g")
endif()
if (NOT DEBUG)
  string(APPEND FFLAGS " -O2 -g")
endif()
string(APPEND CXX_LIBS " -lstdc++")
set(MPICC "cc")
set(MPICXX "CC")
set(MPIFC "ftn")
set(SCC "gcc")
set(SCXX "g++")
set(SFC "gfortran")
