if (compile_threaded)
  string(APPEND CMAKE_C_FLAGS   " -Kopenmp")
  string(APPEND CMAKE_CXX_FLAGS " -Kopenmp")
  string(APPEND CMAKE_Fortran_FLAGS   " -Kopenmp")
  string(APPEND CMAKE_EXE_LINKER_FLAGS  " -Kopenmp")
endif()
string(APPEND CMAKE_C_FLAGS_DEBUG   " -g -Nquickdbg=subchk")
string(APPEND CMAKE_CXX_FLAGS_DEBUG " -g -Nquickdbg=subchk")
string(APPEND CMAKE_Fortran_FLAGS_DEBUG   " -g -Haefosux")
string(APPEND CPPDEFS_DEBUG  "-DYAKL_DEBUG")
string(APPEND CMAKE_C_FLAGS_RELEASE   " -O2")
string(APPEND CMAKE_CXX_FLAGS_RELEASE " -O2")
string(APPEND CMAKE_Fortran_FLAGS_RELEASE   " -O2")
if (COMP_NAME STREQUAL csm_share)
  string(APPEND CMAKE_C_FLAGS " -std=c99")
endif()
string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_R16 -DCPRFJ")
set(CMAKE_Fortran_FORMAT_FIXED_FLAG "-Fixed")
set(CMAKE_Fortran_FORMAT_FREE_FLAG "-Free")
set(MPICC "mpifcc")
set(MPICXX "mpiFCC")
set(MPIFC "mpifrt")
set(SCC "fcc")
set(SCXX "FCC")
set(SFC "frt")
if (COMP_NAME MATCHES "^pio")
  string(APPEND SPIO_CMAKE_OPTS " -DPIO_ENABLE_TOOLS:BOOL=OFF")
endif()
