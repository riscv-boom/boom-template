# RISC-V BOOM Project Template

This is a starter template for your own RISC-V BOOM project.

[BOOM](https://github.com/riscv-boom/riscv-boom) is a superscalar, out-of-order 
processor that implements RISC-V RV64G ISA. BOOM is a synthesizable core that 
targets ASIC processes, and is written in the 
[Chisel hardware construction language](http://chisel.eecs.berkeley.edu).

 Feature | BOOM
--- | ---
ISA | RISC-V (RV64G)
Synthesizable |√
FPGA |√
Parameterized |√
Floating Point (IEEE 754-2008) |√
Atomic Memory Op Support |√
Caches |√
Viritual Memory |√
Boots Linux |√
Privileged Arch v1.11 |√
External Debug |√

You can find more information about BOOM here:
([github.com/riscv-boom/riscv-boom](https://github.com/riscv-boom/riscv-boom)).

**Google group:** (https://groups.google.com/forum/#!forum/riscv-boom)


## Submodules and Subdirectories

The submodules and subdirectories for the project template are organized as
follows.

 * rocket-chip - contains code for the RocketChip generator, Chisel HCL, and FIRRTL
 * rocket-chip/riscv-tools - contains the code for the compiler toolchain and other infrastructure
 * boom - contains code for the BOOM core and tile.
 * scripts - bash scripts for initializing repo, building RISC-V toolchain
 * testchipip - contains the serial adapter, block device, and associated verilog and C++ code
 * verisim - directory in which Verilator simulations are compiled and run
 * vsim - directory in which Synopsys VCS simulations are compiled and run
 * src/main/scala - scala source files for your project extension can go here


## Getting Started

### Checking out the sources

After cloning this repo, you will need to initialize all of the submodules

    git clone https://github.com/riscv-boom/boom-template.git
    cd boom-template
    ./scripts/init-submodules.sh
    
### Building the tools

The tools repo contains the cross-compiler toolchain, frontend server, and
proxy kernel, which you will need in order to compile code to RISC-V
instructions and run them on your design. There are detailed instructions at
https://github.com/riscv/riscv-tools. But to get a basic installation that
will work with BOOM, just the following steps are necessary.

    # You may want to add the following two lines to your shell profile
    export RISCV=/path/to/install/dir
    export PATH=$RISCV/bin:$PATH

    cd boom-template
    ./scripts/build-tools.sh
    
    
### Compiling and running the Verilator simulation

To compile a BOOM simulator, run `make` in the "verisim" directory.
This will elaborate the BoomConfig from the boom.system project.

    cd verisim
    make

An executable called simulator-boom-system-BoomConfig will be produced.
You can then use this executable to run any compatible RV64G code. For instance,
to run one of the riscv-tools assembly tests.

    make output/rv64ui-p-simple.out
    
 Or execute the entire `riscv-tests` suite:
 
    make run
    
 Or just a smaller regression suite:
 
    make run-regression-tests
    
 If you would like to get a `.vpd` waveform, you can instead use:
 
    make output/rv64ui-p-simple.vpd
    
 Or:
 
    make run-debug

If you later create your own project, you can use environment variables to
build an alternate configuration. The different variables are

* PROJECT: The package that contains your test harness class
* CFG_PROJECT: The package that contains your config class
* GENERATOR_PROJECT: The package that contains your Generator class
* MODEL: The class name of your test harness
* CONFIG: The class name of your config

You can manually override them like this

    make PROJECT=yourproject CONFIG=YourConfig
    ./simulator-yourproject-YourConfig ...

### Running random tests with torture ###

RISC-V Torture is included as a submodule and includes the ability to test
BOOM. You can run a single test like so:

    make rgentest R_SIM=../vsim/simv-boom.system-BoomConfig

You can run a nightly test, which runs for a set amount of time or a set
number of failures like this:

    make rnight R_SIM=../vsim/simv-boom.system-BoomConfig OPTIONS="-C config/default.config -t 5 -m 30"
      
# FAQ #

### Searching through the codebase is confusing -- How can I generate ctags for easy code navigation? ###

Located in `boom-template/scripts/` is a quick ctags script called `gen-tags.sh` to help parse the codebase for
relevant tags to use with compatible editors. To generate tags run

    # from the boom-template directory
    ./scripts/gen-tags.sh

This should create a `tags` file in the `boom-template` directory for you to use!

Note that this script requires Exuberant Ctags.

### Git submodules are confusing -- how do I update to the latest BOOM? ###

The [boom](https://github.com/riscv-boom/riscv-boom) and
[rocket-chip](https://github.com/freechipsproject/rocket-chip) repositories are
included as git submodules. This allows us to tag specific versions that should
work together. You can think of git submodules as "pointers" to specific commits.

To update this repository and then update

    cd boom-template
    git pull                         # update this repo and the pointers to the submodules.
    git submodule update --recursive # update the contents of the submodules (and their submodules).
    git status                       # check boom/rocket-chip don't have "new commits".

As rocket-chip itself has additional git submodules, you will need to perform a
recursive submodule update. This may take a while.


### How do I use VCS instead of Verilator? ###

The `verisim` directory manages the Verilator build and run process. 

The `vsim` directory manages the VCS build and run process. 

In either directory you can build and then run the `riscv-tests` using `make && make debug`.

### How do I get a waveform? ###

The testharness/build-system is currently set up to provide a `vpd` or a `fsdb` waveform file.

To get a `vpd` dump, go to the `verisim` or `vsim` directories and
instead of invoking `make`, you can invoke `make debug` to build a
vpd waveform-output-enabled BOOM simulator. The simulator will now be
suffixed with `-debug`.  *Warning:* Verilator takes a very long time
to compile with waveform output enabled.

To run *all* of the riscv-tests with `vpd` waveform output, you can invoke `make run-debug`.

Individually, you run a specific test as `make output/rv64ui-p-simple.out` to run a regular test 
or `make output/rv64ui-p-simple.vpd` to generate a `vpd` waveform.

To get a `fsdb` dump, go to the `vsim` directory and invoke `make fsdb_debug` 
to build a fsdb waveform-output-enabled BOOM
simulator. The simulator will now be suffixed with `fsdb-debug`.  Do
not do this under the `verisim` directory.  You cannot generate a fsdb
enabled Verilator simulator.

You can generate `fsdb` waveforms only when running tests individually with commands of the form 
`make output/rv64ui-p-simple.fsdb`.  To invoke the `verdi` verification tool, run 
`make output/rv64ui-p-simple.verdi`.  If the required fsdb file is not available, this make 
command will generate it first before starting verdi.


Read the Makefile to find all of the special targets.

### BOOM takes forever to compile. ###

You can add to your bash profile:

    export MAKEFLAGS="-j `echo \`nproc\`*2/2|bc`" 
    
This will spawn as many threads as you have cores when invoking `make`, speed up compilation, 
and run the `riscv-tests` in parallel. 

**Warning**: if you are performing VCS simulation you will burn through your precious licenses.

**Warning**: if you are writing a lot of data to the *.out files or *.vpd files you may hose your file system.

Unfortunately, many of the structures in an OOO processor scale worse than linearly. 
Also, some compilers struggle with large functions that arise when you turn the auto-generated
Verilog into straight-line C++ code that is flattened across the whole design. 
As such, VCS compiles much faster than Verilator (but runs much slower).

Here are some times as measured on my machine using the verilator simulator:

  * `make CONFIG=MegaBoomConfig run` takes 57 minutes.

  * `make CONFIG=BoomConfig run` takes 39 minutes.
  
  * `make CONFIG=SmallBoomConfig run` takes 15 minutes.

To improve the speed of your run-debug loop, you can instead invoke a smaller set of tests:

````
make run-regression-tests
````

### Help! BOOM isn't working! ###

First verify the software is not an issue. Run spike first:

````
# Verify it works on spike.
spike --isa=rv64imafd my_program

# Then we can run on BOOM.
./emulator-freechips.rocketchip.system-SmallBoomConfig my_program 
````

Also verify the riscv-tools you built is the one pointed to within 
the boom-template/rocket-chip/riscv-tools repository. Otherwise a 
version mismatch can easily occur!


### How do I debug BOOM? ###

I recommend opening up the waveform and starting with the following signals, 
located in `TestDriver.testHarness.dut.tile.core`:

   * debug_tsc_reg (cycle counter)
   * debug_irt_reg (retired instruction counter)
   * rob_io_commit_valids_* (the commit signals)
   * csr_io_pc (roughly the commit pc)
   * br_unit_brinfo_valid (was a branch/jalr resolved?)
   * br_unit_brinfo_mispredict (was a branch/jalr mispredicted?)
   * dis_valids_* (are any instructions being dispatched to the issue units?)
   * dis_uops_*_pc (what are the PCs of the dispatched instructions?)

### How do I get a commit log out of BOOM? Out of spike? ###

Go to `boom/src/main/scala/common/consts.scala` and change `COMMIT_LOG_PRINTF`
to `true`. That will output a log of committed instructions.

You can rebuild the `spike` ISA simulator to also print out a commit log to 
compare against. 

    cd rocket-chip/riscv-tools/riscv-isa-sim;
    mkdir build
    cd build
    ../configure --prefix=$RISCV --with-fesvr=$RISCV --with-isa=rv64imafd --enable-commitlog

Your new spike will ALWAYS print out a commit log to `stderr`. I recommend 
you change the `prefix` to a different directory (and also build a new riscv-fesvr 
to be placed in this same directory), rename your spike to something else
(e.g., `lspike`), and add this `prefix/bin` to your path. In this manner, you won't
overwrite your regular `spike` binary.


### Why are the commit logs of BOOM and spike so different? ###

Frustrating, right? 

By default, the BOOM simulators built within the `verisim` and `vsim` 
directories are tethered to the riscv-fesvr (to handle binary loading 
and proxying syscalls). The actual binary loading is performed using
the Debug Transport Module (DTM) which implements the RISC-V External
Debug Specification. The `riscv-fesvr` magically sends signals to the 
DTM to interrupt BOOM and have it execute out of the Debug Program 
Buffer. In this manner, BOOM slowly loads the binary into its target
memory. 

To proxy syscalls, the DTM occasionally interrupts the BOOM core to 
have it read a special `tohost` memory location. If the `tohost` value
is non-zero, the BOOM core has a message for the riscv-fesvr to handle.

Spike is also tethered to the riscv-fesvr, but it can instantly load the 
test binary directly (and magically) into its target memory. There is no
invocation of the Debug specification to do this. 

Eventually, BOOM and spike will converge after they have each loaded the
test binary into their memories. They will again diverge on ocassion to
send proxy syscalls to the host, spinning for indeterminate amounts of
time while waiting for a `fromhost` message (by repeatedly reading an
agreed-upon `fromhost` address in memory).

There are other ways to load binaries and control the design-under-test.
The (https://github.com/ucb-bar/testchipip) repository provides a Tethered
Serial Interface (TSI) which can directly and coherently write into the target
memory to load programs and query for `tohost` communications. This requires
a different `bootrom` as well as different top-level I/O connections to
wire-up this TSI. This is less invasive than repeatedly polling through the
DTM, but also more special-purpose built.

Or, one could build a self-hosting BOOM system. But you need to provide the
appropriate drivers, IP blocks, and `bootrom` to communicate with the system
in some manner. An example self-hosted rocket-chip system that follows the 
`project-template` layout is the (https://github.com/sifive/freedom) platform.

Processors are hard.

### VIM/bash isn't a development environment! How do I setup an IntelliJ IDE? ###

Boom-template/rocket-chip/boom comes with a quite a project hierarchy that may be hard
to keep track of in its entirety. Here's some steps to get started with IntelliJ. 
This section is a work-in-progress, so please share your own tips and hints on the 
mailing list.

**Step 1:** Install a JDK (you have probably already done this, but you need to find it).
If you are using OSX, I recommend:

```bash
brew tap caskroom/versions
brew update
brew cask install java8
```

This will give you a jdk that is probably in `/Library/Java/JavaVirtualMachines`.

**Step 2:** Follow the above instructions to check out `boom-template` and build a BOOM emulator.
Run it through some tests to make sure everything works. This is important, as this will
build a `lib` file full of `jar` files of Chisel, FIRRTL, RocketChip, BOOM, and others.

**Step 3:** Import a project in IntelliJ. Select `boom-template/build.sbt`. Use Java 1.8. 

**Step 4:** Right-click on `boom-template/lib` in your project hierarchy and `Add as Library`.

**Step 5:** Right-click on `boom-template/boom/src` and `Mark Directory as -> Sources Root`. 
IntelliJ can't find source code that is not under `boom-template/src/main/scala` without help.

**Step 6:** Right-click on `boom/src/main/scala/system/Generator` and `Run`. It will fail.

**Step 7:** Open `Run->Edit Configurations..` and add the following arguments to your
`program arguments` (main class should be `boom.system.Generator`). Replace `${TEMPLATE}`
with what is appropriate for your system.

```bash
${TEMPLATE}/verisim/generated-src boom.system TestHarness boom.system BoomConfig
```

That string comes from `Makefrag-variables`. You can change BoomConfig to match your desired
`${CONFIG}`.

**Step 8:** `Run` your `Generator` target. It should now generate firrtl code. However,
the rest of the `boom-template` system relies on Makefiles to string everything together.
You can either build additional `Run` configurations, or connect to the existing Makefiles.

**Step 9:** Go to `Preferences->Plugins` and add `Makefile support`.

**Step 10:** Right-click on on `boom-template/verisim/Makefile` and `run Makefile.`
This should compile a BOOM verilator-based emulator.

**Step 11:** Edit your `Run->Edit Configurations..` to add new Run configurations for
additional Make targets and `${CONFIG}` options. For development, 
`make $CONFIG=SmallBoomConfig run-regression-tests` is one recommended command.
You can also choose to invoke Make manually in your terminal.

**Step 12:** Browse the boom source code. Notice that you can highlight a variable and see
its definition (or see its instantiations). You can also browse the `View->Tool Windows->Structure`
to see what variables are in scope for a particular class. Click on `show inherited` to see more,
in particular, what the `traits` might be bringing in to scope!

**Step 13:** Provide feedback and pull requests to this README (or elsewhere). I am hoping
that some find this useful and can provide more guidance on how to improve the IntelliJ/
boom-template flow for those that may follow.


# Additional Information from the Project-Template README

The original source of boom-template derives from (https://github.com/ucb-bar/project-template).
Please visit it to learn more about adding your own devices or submodules to this template.

