
CC=g++
CFLAGS=-Wall -Werror -g -I$(SIMULATOR_ROOT)/interchiplet/includes
INTERCHIPLETLIB=$(SIMULATOR_ROOT)/interchiplet/lib/libinterchiplet_app.a
SNIPER_EXEC=$(SIMULATOR_ROOT)/snipersim/run-sniper

NVCC=nvcc

BENCHMARK_ROOT=$(SIMULATOR_ROOT)/benchmark/matadd

SNIPER_SRCS=matadd.cpp
SNIPER_OBJS=matadd.o
SNIPER_TARGET=matadd_cpu

GPGPUSIM_SRCS=matadd.cu
GPGPUSIM_TARGET=matadd_cu

all: sniper_target gpgpusim_target

sniper_target: $(SNIPER_OBJS)
	$(CC) -g $(SNIPER_OBJS) $(INTERCHIPLETLIB) -o $(SNIPER_TARGET) 

%.o: %.cpp
	$(CC) $(CFLAGS) -c $< -o $@


gpgpusim_target:
	$(NVCC) --cudart shared $(GPGPUSIM_SRCS) -o $(GPGPUSIM_TARGET)

run:
	./$(GPGPUSIM_TARGET) 0 1 > gpgpusim.0.1.log 2>&1 &
	$(SNIPER_EXEC) --curdir $(BENCHMARK_ROOT) -- $(BENCHMARK_ROOT)/$(SNIPER_TARGET) 0 0 > sniper.log 2>&1

run_cpu:
	$(SNIPER_EXEC) --curdir $(BENCHMARK_ROOT) -- $(BENCHMARK_ROOT)/$(SNIPER_TARGET) 0 0

run_gpu:
	./$(GPGPUSIM_TARGET) 0 1 > gpgpusim.0.1.log 2>&1 &

dbg: $(SNIPER_TARGET)
	cd $(BENCHMARK_ROOT) && gdb ./$(SNIPER_TARGET) -- $(BENCHMARK_ROOT)/$(SNIPER_TARGET) 0 0

clean:
	rm -rf bench* buffer* message_record.txt
	rm -rf _app_cuda_version_* _cuobjdump_list_ptx_* gpgpusim_power_report_* *.ptx *.ptxas gpgpusim.*.log gpgpu_inst_stats.txt sniper.log
	rm -rf sim.cfg sim.info sim.out sim.stats.sqlite3
	rm -rf checkpoint_files
	rm -rf gpuRead* cpuRead*

cleanall:
	make clean 
	rm -rf $(SNIPER_OBJS) $(GPGPUSIM_TARGET) $(SNIPER_TARGET)
