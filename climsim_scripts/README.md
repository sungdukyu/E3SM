# ClimSim-enabled E3SM
This document provides how to run E3SM with a ClimSim emulator. While the configurations in this example are based on NERSC Perlmutter, other machines can be used. If porting is necessary, please refer to [the CIME document](https://e3sm.org/model/running-e3sm/supported-machines/)

This version of ClimSim-E3SM relies on [FKB](https://www.hindawi.com/journals/sp/2020/8888811/) to link an ML emulator inside E3SM's Fortran codebase. If FKB is not installed previously on a machine, see Appendix B for installing FKB.

For general E3SM uses, refer to the following resources
- [E3SM tutorials](https://e3sm.org/about/events/e3sm-tutorials/)
- [CESM tutorials](https://www2.cesm.ucar.edu/events/tutorials/2021/coursework.html) * While CESM is a different model, CESM and E3SM have shared history and use [CIME](https://esmci.github.io/cime/versions/master/html/index.html#). So, their workflow (create -> setup -> build -> submit) is very similar.
- [CIME manual](https://esmci.github.io/cime/versions/master/html/users_guide/index.html) (This document contains the information about many commands in the step-by-step instruction, e.g., case.setup, case.build, case.submit, xmlchange, ...)

## Step-by-step instructions
### [0] Download E3SM
```
> git clone https://github.com/sungdukyu/E3SM/
> cd E3SM
> git checkout climsim/fkb
> git submodule update --init --recursive
> E3SMROOT=`pwd`                                # Root of the E3SM codes
```

### [1] Create a case
(Make sure `E3SMROOT` is set correctly!)
```
> cd $E3SMROOT
> CASEPATH=${SCRATCH}/FKB-E3SM-test1 # full pathname of your case (simulation)
> COMPSET=F2010-MMF1                 # F2010-MMF1 for real-geography; FAQP-MMF1 for aquaplanet
> RESOLUTION=ne4pg2_ne4pg2           # ne4pg2_ne4pg2 for 'low-res'; ne30pg2_oECv3 for 'high-res'
> MACHINE=pm-gpu                     # pm-gpu for NERSC Perlmutter GPU nodes; pm-cpu for CPU nodes
> COMPILER=gnugpu                    # gnugpu for pm-gpu; gnu for pm-cpu
> num_nodes=2                        # number of requested compute nodes, e.g., 2 for 'low-res'; 32 for 'high-res'
> max_mpi_per_node=4                 #  4 for pm-gpu; 64 for pm-cpu
> atm_nthrds=8                       #  8 for pm-gpu;  1 for pm-cpu
> max_task_per_node=32               # 32 for pm-gpu; 64 for pm-cpu
> atm_ntasks=$((max_mpi_per_node*num_nodes))
> ./cime/scripts/create_newcase --case ${CASEPATH} --compset ${COMPSET} --res ${RESOLUTION} --mach ${MACHINE} --compiler ${COMPILER} --pecount ${atm_ntasks}x${atm_nthrds}
```

### [2] update XML files
```
> cd $CASEPATH

# update directories for build and run
> ./xmlchange EXEROOT=${CASEPATH}/build
> ./xmlchange RUNDIR=${CASEPATH}/run
> ./xmlchange DOUT_S_ROOT=${CASEPATH}/archive

# set the simulation type (initial run or continued run)
> ./xmlchange RUN_TYPE=startup # if it's restart (e.g., branch or hybrid), need to update RUN_REFDIR, GET_REFCASE, RUN_REFCASE, RUN_REFDATE, RUN_REFTOD, RUN_STARTDATE, etc.

# machine specific setting
> ./xmlchange MAX_MPITASKS_PER_NODE=4 # 64 for pm-cpu and 4 for pm-gpu
> ./xmlchange MAX_TASKS_PER_NODE=32 # 64 for pm-cpu; 32 for pm-gpu

# build options
> CLIMSIM_CPP="-DCLIMSIM -DCLIMSIM_DIAG_PARTIAL -DCLIMSIMDEBUG"
> ./xmlchange PIO_NETCDF_FORMAT="64bit_data"
> ./xmlchange --append CAM_CONFIG_OPTS=" -cppdefs ' ${CLIMSIM_CPP} '  "

# set simulation length
> ./xmlchange STOP_OPTION=ndays,STOP_N=8,RESUBMIT=0

# slurm options
> ./xmlchange JOB_QUEUE=debug              # (machine dependant) queue name (e.g., for Perlmutter, debug or regular)
> ./xmlchange JOB_WALLCLOCK_TIME=00:10:00  # Requested wall clock time
> ./xmlchange CHARGE_ACCOUNT=...           # Account number for allocation
> ./xmlchange PROJECT=...                  # Account number for allocation
```
`-DCLIMSIM` should always be included in `CLIMSIM_CPP` to enable neural network inference. `-DCLIMSIM_DIAG_PARTIAL` is optional for diagnostic partial-coupling output (see Appendix C). `-DCLIMSIMDEBUG` is also optional for extra debugging logs.

### [3] update user_nl_eam
(See Appendix A to learn different ClimSim FKB configurations)

```
> cd $CASEPATH
> cat << EOF >> user_nl_eam

! Mandatory: turn off aerosol optical calculations
&radiation
do_aerosol_rad = .false.
/

! Optional: turns on extra validation of physics_state objects in physics_update. Used mainly to track down which package is the source of invalid data in state.
&phys_ctl_nl
state_debug_checks = .true.
/

! ClimSim FKB configuration
&climsim_nl
inputlength     = 425              ! length of the input vector
outputlength    = 368              ! length of the output vector
cb_nn_var_combo = 'v2'             ! input/output variable combo
input_rh        = .false.          ! .true. if input 'state_q0001' is relative humidity; .false. if specific humidity
cb_fkb_model    = '${E3SMROOT}/climsim_scripts/mlp-001.linear-out.h5.txt'  ! full pathname for FKB model weights
cb_inp_sub      = '${E3SMROOT}/climsim_scripts/inp_sub.v2.txt'             ! full pathname for input vector subtraction constants
cb_inp_div      = '${E3SMROOT}/climsim_scripts/inp_div.v2.txt'             ! full pathname for input vector division constants
cb_out_scale    = '${E3SMROOT}/climsim_scripts/out_scale.v2.txt'           ! full pathname for output vector scaling constants

! partial coupling setup
cb_partial_coupling = .true.
cb_partial_coupling_vars = 'ptend_t', 'ptend_q0001','ptend_q0002','ptend_q0003', 'ptend_u', 'ptend_v', 'cam_out_PRECC', 'cam_out_PRECSC', 'cam_out_NETSW', 'cam_out_FLWDS', 'cam_out_SOLS', 'cam_out_SOLL', 'cam_out_SOLSD', 'cam_out_SOLLD'
/

! history tape setup
&cam_history_nl
fincl2 = 'state_t_0:I:I', 'state_q0001_0:I', 'state_q0002_0:I', 'state_q0003_0:I', 'state_u_0:I', 'state_v_0:I', 'cam_out_NETSW_0:I', 'cam_out_FLWDS_0:I', 'cam_out_PRECSC_0:I', 'cam_out_PRECC_0:I', 'cam_out_SOLS_0:I', 'cam_out_SOLL_0:I', 'cam_out_SOLSD_0:I', 'cam_out_SOLLD_0:I'
fincl3 = 'state_t_1:I', 'state_q0001_1:I', 'state_q0002_1:I', 'state_q0003_1:I', 'state_u_1:I', 'state_v_1:I', 'cam_out_NETSW_1:I', 'cam_out_FLWDS_1:I', 'cam_out_PRECSC_1:I', 'cam_out_PRECC_1:I', 'cam_out_SOLS_1:I', 'cam_out_SOLL_1:I', 'cam_out_SOLSD_1:I', 'cam_out_SOLLD_1:I'
fincl4 = 'state_t_2:I', 'state_q0001_2:I', 'state_q0002_2:I', 'state_q0003_2:I', 'state_u_2:I', 'state_v_2:I', 'cam_out_NETSW_2:I', 'cam_out_FLWDS_2:I', 'cam_out_PRECSC_2:I', 'cam_out_PRECC_2:I', 'cam_out_SOLS_2:I', 'cam_out_SOLL_2:I', 'cam_out_SOLSD_2:I', 'cam_out_SOLLD_2:I'
fincl5 = 'state_t_3:I', 'state_q0001_3:I', 'state_q0002_3:I', 'state_q0003_3:I', 'state_u_3:I', 'state_v_3:I', 'cam_out_NETSW_3:I', 'cam_out_FLWDS_3:I', 'cam_out_PRECSC_3:I', 'cam_out_PRECC_3:I', 'cam_out_SOLS_3:I', 'cam_out_SOLL_3:I', 'cam_out_SOLSD_3:I', 'cam_out_SOLLD_3:I'

fincl6 = 'T:I', 'Q:I', 'CLDLIQ:I', 'CLDICE:I', 'U:I', 'V:I', 'TS:I', 'PS:I', 'LHFLX:I', 'SHFLX:I', 'SOLIN:I', 'PRECC:I', 'PRECSC:I'

nhtfrq = 0,1,1,1,1,1
mfilt  = 0,1,1,1,1,1
/

EOF
```

### [4] setup/build/submit
```
> cd $CASEPATH
> ./case.setup
> ./case.build
> ./case.submit
```

## Appendix A: How to configure ClimSim using `user_nl_eam`
- Shared options
```
&radiation
do_rad_aer=.false.
/

&climsim_nl
inputlength = ...      !(integer) the length of input vector
outputlength = ...     !(integer) the length of output vector

cb_nn_coupling_step = ... !(integer) the timestep where NN coupling starts. Default: 72.
                          !           before this timestep, a regular MMF (CRM) is running.
                          !           note that the default timestep for E3SM-MMF is 20 minutes.

cb_nn_var_combo = ...  !(string) a preset name for a specific input/output variable combination
cb_inp_sub = ...       !(string) pathname of input vector subtraction constant text file
cb_inp_div = ...       !(string) pathname of input vector division constant text file
cb_out_scale = ...     !(string) pathname of output vector scaling constant text file
/
```
- Single model inference
```
(add shared option)
&climsim_nl
cb_fkb_model = ...  !(string) pathname of FKB model weight text file
/
```
- Ensemble model inference
```
(add shared option)
&climsim_nl
cb_do_ensemble = ...         !(logical) .true. for ensemble inference; .false. for single-model inference
cb_ens_size = ...            !(integer) number of ensemble models
cb_ens_fkb_model_list = ...  !(strings) pathnames for FKB model weight text files, e.g., 'mlp-1.txt','mlp-2.txt','mlp-3.txt','mlp-4.txt','mlp-5.txt'
/
```

- Stochastic ensemble inference
```
(add shared option)
&climsim_nl
cb_do_ensemble = ...
cb_ens_size = ...
cb_ens_fkb_model_list = ...
cb_random_ens_size = ...     !(integer) number of ensemble members to make a mean inference.
                             !          e.g., if cb_ens_size=10 and cb_random_ens_size=5,
                             !                5 randomly chosen emulator models out of 10 are used to make a mean inference
/
```

- Partial coupling
```
(add shared option)
(add single-model or ensemble model option)
&climsim_nl
cb_partial_coupling = ...  !(logical) .true. if input state_q0001 is relative humidity; .false. if specific humidity
cb_partial_coupling_vars = !(strings) a list of NN variables to be prognostically coupled
/
```

- Relative humidity
```
(add shared option)
(add single-model or ensemble model option)
&climsim_nl
input_rh = ...  !(logical) .true. if input state_q0001 is relative humidity; .false. if specific humidity
/
```

## Appendix B: Install FKB
Unfortunately, [the official FKB repository](https://github.com/scientific-computing/FKB) is no longer maintained. So, [a different version of FKB](https://github.com/sungdukyu/FKB64), which fixed several bugs and added more activation functions, is used here.

- Install FKB:

```
> # (move to the directory where you want to install FKB)
> DIR=`pwd`
> git clone https://github.com/sungdukyu/FKB64
> cd FKB64 
> # Set compiler options in build_steps.sh, by modifying FC (https://github.com/sungdukyu/FKB64/blob/master/build_steps.sh#L10)
> sh build_steps.sh  # compile FKB
```

- Modify machine-specific CMAKE macro in E3SM
CMAKE macro files for supported machines are in `$E3SMROOT/cime_config/machines/cmake_macros`. Add the following two lines to the right CMAKE macro file depending on machines and compilers. In this example, we are adding to cmake macro file for Perlmutter / GPU. 


```
> cmakefile=$E3SMROOT/cime_config/machines/cmake_macros/gnugpu_pm-gpu.cmake
> cat << EOF > $cmakefile
string(APPEND CMAKE_Fortran_FLAGS " -I$DIR/FKB64/build/include ")
string(APPEND CMAKE_EXE_LINKER_FLAGS " -L$DIR/FKB64/build/lib -lneural ")
EOF
```

## Appendix C: EAM output fields for the partial coupling
To maximize the diagnostic capability, the partial coupling can save ClimSim output variables (state_t, state_q0001, state_q0002, state_q0003, state_u, state_v, cam_out_NETSW, cam_out_FLWDS, cam_out_SOLL, cam_out_SOLS, cam_out_SOLLD, cam_out_SOLSD, cam_out_PRECC, cam_out_PRECSC) at each time step of the partial coupling. The suffix of a variable name is indicative of the time point when the variable is saved.
- "_0" (e.g., state_t_0): Input stave
- "_1" (e.g., state_t_1): Output of SP (CRM) calculation
- "_2" (e.g., state_t_2): Output of NN calculation
- "_3" (e.g., state_t_3): Partial coupled output, i.e., the combination of the above two based on the namelist variable cb_partial_coupling_vars


# To-be-added
- how to define cb_nn_var_combo
- fincl. partially coupled variable workflow.
