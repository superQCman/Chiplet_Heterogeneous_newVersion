CC=g++
CFLAGS=-Wall -Werror -g -I$(SIMULATOR_ROOT)/interchiplet/includes -I$(HOME)/local/mpich/mpich-4.2.0/src/include
INTERCHIPLETLIB=$(SIMULATOR_ROOT)/interchiplet/lib/libinterchiplet_app.a
SNIPER_EXEC=$(SIMULATOR_ROOT)/snipersim/run-sniper

all:direct

direct:
	mpicxx -g Mympi.cpp -o Mympi
run_4:
	$(SIMULATOR_ROOT)/snipersim/run-sniper -c gainestown -n 4 --mpi --mpi-ranks=4 -- ./Mympi

clean:
	rm -rf bench* buffer* message_record.txt
	rm -rf _app_cuda_version_* _cuobjdump_list_ptx_* gpgpusim_power_report_* *.ptx *.ptxas gpgpusim.*.log gpgpu_inst_stats.txt
	rm -rf sim.cfg sim.info sim.out sim.stats.sqlite3
	rm -rf checkpoint_files
