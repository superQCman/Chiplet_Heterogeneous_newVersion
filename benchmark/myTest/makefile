
CC=g++
CFLAGS=-Wall -Werror -g -I$(SIMULATOR_ROOT)/interchiplet/includes
INTERCHIPLETLIB=$(SIMULATOR_ROOT)/interchiplet/lib/libinterchiplet_app.a
SNIPER_EXEC=$(SIMULATOR_ROOT)/snipersim/run-sniper

NVCC=nvcc

BENCHMARK_ROOT=$(SIMULATOR_ROOT)/benchmark/myTest

SNIPER_SRCS=matmul.cpp
SNIPER_OBJS=matmul.o
SNIPER_TARGET=matmul_cpu

GPGPUSIM_SRCS=test.cu
GPGPUSIM_TARGET=test_cu

all:gpgpusim_target

gpgpusim_target:
	$(NVCC) --cudart shared $(GPGPUSIM_SRCS) -o $(GPGPUSIM_TARGET)

debug:
	$(NVCC) --cudart shared $(GPGPUSIM_SRCS) -g -G -o $(GPGPUSIM_TARGET) 

gdb:
	cuda-gdb ./$(GPGPUSIM_TARGET) 

clean:
	rm -rf _app_cuda_version_* _cuobjdump_list_ptx_* gpgpusim_power_report_* *.ptx *.ptxas test*.log gpgpu_inst_stats.txt

run_add:
	./test_cu 0 > test.log 2>&1 

run_mul:
	./test_cu 1 >test.log 2>&1

