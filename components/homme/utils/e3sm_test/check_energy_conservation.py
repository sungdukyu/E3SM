#!/usr/bin/env
# python3

import os, sys, re
#import numpy as np

def readall(fn):
    with open(fn,'r') as f:
        txt = f.read()
    return txt

def greptxt(pattern, txt):
    return re.findall('(?:' + pattern + ').*', txt, flags=re.MULTILINE)

def grep(pattern, fn):
    txt = readall(fn)
    return greptxt(pattern, txt)

def read_atm_modelio(case_dir):
    filename = case_dir + os.path.sep + 'CaseDocs' + os.path.sep + 'atm_modelio.nml'
    ln = grep('diro = ', filename)[0]
    return ln.split()[2].split('"')[1]

def get_atm_log(run_dir):
    filenames = os.listdir(run_dir)
    atm_fn = None
    for f in filenames:
        if 'atm.log' in f:
            atm_fn = f
            break
    return run_dir + os.path.sep + atm_fn

def uncompress(filename):
    if '.gz' in filename:
        os.system('gunzip {}'.format(filename))
        return filename[:-3]
    return filename

def parse_tracer_index(atm_log_fn, tracer_name):
    state = 0
    with open(atm_log_fn, 'r') as f:
        for ln in f:
            if state == 0:
                if 'Advected constituent list:' in ln: state = 1
            elif state == 1:
                if tracer_name in ln:
                    toks = ln.split()
                    tracer_idx = int(toks[0])
                    break
    return tracer_idx

def parsetime(ln):
    toks = ln.split()
    val = float(toks[2])
    return val

def parseqmass(ln):
    toks = ln.split()
    return float(toks[-1])
    
def gather_energy_data(atm_log_fn):
    d = {'ttime': [], 'rr': []}

    #file lines
    #nstep, te        1   0.25844877776869764E+10   0.25845216307593832E+10   0.46806180877977696E-03   0.98515700139519613E+05
    #nstep, d(te)/dt, rr        1   0.35896133760546986E+06  -0.94100652141702469E+02
    #nstep, di        1   0.35905543825761159E+06

    ll = "nstep, di"
    with open(atm_log_fn, 'r') as f:
        for ln in f:
            if ll in ln: 
                nstep = float(ln.split()[2])
                rr = float(ln.split()[3])
                d['ttime'].append(nstep)
                d['rr'].append(rr)
                #print (nstep)
                #print (rr)
    return d

def conservative(start_time, time, rr, tol, verbose):
   
    shortarr=rr[start_time:]
    aver = sum(shortarr)/len(shortarr)
    #stdd = np.std(np.array(rr))
    if (verbose):
        #print('RR average {:1.3e}, std {:1.3e}, min {:1.3e}, max {:1.3e}'.format(aver, std,min(rr),max(rr)))
        print('RR average {:1.3e}, min {:1.3e}, max {:1.3e}'.format(aver,min(rr),max(rr)))
        #maxabs = max(abs(rr))
        maxx = abs(aver)
    return maxx <= tol


#############################################################3


#tracer_name = 'CO2_FFF'

print("hereeeee ")

case_dir = sys.argv[1]

#uncomment in the repo!!!!!!
#run_dir = read_atm_modelio(case_dir)
#atm_fn = get_atm_log(run_dir)
atm_fn = get_atm_log(".")

atm_fn = uncompress(atm_fn)
print('Using log file {}'.format(atm_fn))
#tracer_idx = parse_tracer_index(atm_fn, tracer_name)
#print('Tracer {} has index {}'.format(tracer_name, tracer_idx))
d = gather_energy_data(atm_fn)

good = (conservative(3,d['ttime'],d['rr'],2e-13,True))

#good = (conservative('dry M', d['day'], d['dryM'], 1e-11, True) and
#        conservative('tracer {}'.format(tracer_idx), d['day'], d['qmass'], 2e-13, True))

if good:
    print('PASS')
    sys.exit(0)
else:
    print('FAIL')
    sys.exit(1) # non-0 exit will make test RUN phase fail, as desired
