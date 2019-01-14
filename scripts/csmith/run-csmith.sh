# Script to run the csmith random test generator multiple times
# 
# Usage:
#     ./run-csmith.sh SIMULATOR_BINARY [RUN_AMT] [PARALLEL_INSTANCES]
#         RUN_AMT is the amount of times to run the csmith test
#         PARALLEL_INSTANCES is the amount of instances to spawn in parallel
#     Defaults: RUN_AMT = infinite, PARALLEL_INSTANCES = 1

TEST_NAME=test
SIM=$1
RUN_AMT=$2
P_INST=$3
INF=false

# Make output directory
OUTPUT_DIR=output
SRC_DIR=sources
mkdir -p output

# Exit everything on one ctrl+c
trap kill_group SIGINT
kill_group(){
    echo ""
    echo "[ALL] Killing instances."
    kill 0
}

# Run the csmith test once
run_once () {
    SEED=$(date +%m%d%Y%H%M%S%N)
    echo "[$1] Running csmith test with seed=$SEED"
    csmith --seed $SEED > $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c

    # Build both a RISCV binary and normal binary

    # Test x86-64 first
    gcc -I$RISCV/include/csmith-2.4.0 -w $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c -o $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin
    timeout 1s ./$OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin | awk '{print tolower($0)}' > $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "[$1] x86-64 binary timed out. Discard and start over."
        rm $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c
        return 0
    fi

    # Test RISCV spike version
    riscv64-unknown-elf-gcc -w -I./$SRC_DIR -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -o $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c $SRC_DIR/syscalls.c $SRC_DIR/crt.S -static -nostdlib -nostartfiles -lm -lgcc -T $SRC_DIR/link.ld -I$RISCV/include/csmith-2.4.0
    timeout --foreground 10s spike $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv 1> $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out 2> $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.log
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "[$1] Spike timed out. Discard and start over."
        rm $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.log
        return 0
    fi
    
    # Compare x86-64 and Spike
    cmp -s $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "[$1] Spike produces wrong result compared to x86-64 binary. Discard and start over."
        rm $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.log
        return 0
    fi

    # Compare simulator output versus spike
    $SIM $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv 1> $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.out
    cmp -s $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "[$1] Simulator produced wrong result."
        $SIM $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv +verbose +vcdplusfile=$OUTPUT_DIR/${TEST_NAME}-$1-$SEED.vpd 1> $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.out 2> $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.log
        echo "[$1]  Vpd of error file:     $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.vpd"
        echo "[$1]  Simulator output file: $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.out"
        echo "[$1]  Simulator log file:    $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.log"
        exit 1
    else
        echo "[$1] Simulator and spike agree."
        rm $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.bin $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.host.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.c $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.riscv $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.out $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.spike.log $OUTPUT_DIR/${TEST_NAME}-$1-$SEED.sim.out
        return 0
    fi
}

run() {
    if [ $INF == true ]; then
        while true;
        do
            run_once $1
        done
    else
        for j in `seq 1 $RUN_AMT`;
        do
            run_once $1
        done
    fi
}

# Start of script
if [ -z "$SIM" ]; then
    echo "Forgot simulator binary."
    exit 1
fi

if [ -z "$RUN_AMT" ]; then
    echo "Defaulting to infinite runs."
    INF=true
fi

if [ -z "$P_INST" ]; then
    echo "Defaulting to 1 instance."
    P_INST=1
fi

if [ $INF == true ]; then
    echo "Spawning $P_INST instances, running csmith infinite times"
else
    echo "Spawning $P_INST instances, running csmith $RUN_AMT times"
fi

for i in `seq 1 $P_INST`;
do
    run $i &
done
wait
