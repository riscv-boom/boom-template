
run_once () {
    echo "Running csmith test once"
    csmith > test.c
    riscv64-unknown-elf-gcc -w -I./ -DPREALLOCATE=1 -mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -o test test.c syscalls.c crt.S -static -nostdlib -nostartfiles -lm -lgcc -T test.ld -I$RISCV/include/csmith-2.4.0
    gcc -I$RISCV/include/csmith-2.4.0 -w test.c -o test.bin

    timeout 1s ./test.bin | awk '{print tolower($0)}' > test.host.out
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "x64 timed out"
        return 0
    fi

    timeout --foreground 10s spike test 1> test.spike.out 2> test.spike.log
    RV=$?
    if [ $RV -ne 0 ]; then
        echo "spike timed out"
        return 0
    fi
    
    cmp -s test.spike.out test.host.out
    RV=$?

    if [ $RV -ne 0 ]; then
        echo "Spike produces wrong result"
        return 0
    fi
    $1 test 1> test.sim.out
    cmp -s test.sim.out test.spike.out
    RV=$?

    if [ $RV -ne 0 ]; then
        echo "Simulator produced wrong result"
        $1 test +verbose +vcdplusfile=test.vpd 1> test.sim.out 2> test.sim.log
        exit 1
    else
        echo "Simulator and spike agree"
        return 0
    fi
}

while true; do
    run_once $1
done
