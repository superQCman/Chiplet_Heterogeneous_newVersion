# Project environment
# SIMULATOR_ROOT, defined by setup_env.sh
BENCHMARK_ROOT=$(SIMULATOR_ROOT)/benchmark/conv_4GPU

# Compiler environment of C/C++
CC=g++
CFLAGS=-Wall -Werror -g -I$(SIMULATOR_ROOT)/interchiplet/includes
INTERCHIPLET_C_LIB=$(SIMULATOR_ROOT)/interchiplet/lib/libinterchiplet_c.a

# C/C++ Source file
C_SRCS=conv.cpp
C_OBJS=obj/conv.o
C_TARGET=bin/conv_c

# Compiler environment of CUDA
NVCC=nvcc
CUFLAGS=--compiler-options -Wall -I$(SIMULATOR_ROOT)/interchiplet/includes

# CUDA Source file
CUDA_SRCS=conv.cu
CUDA_OBJS=cuobj/conv.o
CUDA_TARGET=bin/conv_cu

NPU_SRCS=cim.cpp
NPU_OBJS=obj/cim.o
NPU_TARGET=bin/cim

MNSIM_SRCS=mnsim.cpp
MNSIM_OBJS=obj/mnsim.o
MNSIM_TARGET=bin/mnsim

all: bin_dir obj_dir cuobj_dir C_target CUDA_target

# C language target
C_target: $(C_OBJS)
	$(CC) $(C_OBJS) $(INTERCHIPLET_C_LIB) -o $(C_TARGET)

# CUDA language target
CUDA_target: $(CUDA_OBJS)
	$(NVCC) -L$(SIMULATOR_ROOT)/gpgpu-sim/lib/$(GPGPUSIM_CONFIG) --cudart shared $(CUDA_OBJS) -o $(CUDA_TARGET)

# NPU language target
NPU_target: $(NPU_OBJS)
	$(CC) $(NPU_OBJS) $(INTERCHIPLET_C_LIB) -o $(NPU_TARGET)

# MNSIM language target
MNSIM_target: $(MNSIM_OBJS)
	$(CC) $(MNSIM_OBJS) $(INTERCHIPLET_C_LIB) -o $(MNSIM_TARGET)

# Rule for C object
obj/%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@

# Rule for Cuda object
cuobj/%.o: %.cu
	$(NVCC) $(CUFLAGS) -c $< -o $@

# Directory for binary files.
bin_dir:
	mkdir -p bin

# Directory for object files for C.
obj_dir:
	mkdir -p obj

# Directory for object files for CUDA.
cuobj_dir:
	mkdir -p cuobj

run:
	../../interchiplet/bin/interchiplet ./conv.yml -w 6
# Clean generated files.
clean:
	rm -rf bench.txt delayInfo.txt buffer* message_record.txt
	rm -rf proc_r*_t* *.log
	

clean_all:clean
	rm -rf obj cuobj bin