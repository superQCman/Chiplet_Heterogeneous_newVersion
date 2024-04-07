NVCC=nvcc
GPU_TARGET=tran_cu
GPU_RCS=tran.cu
all:
	$(NVCC) --cudart shared $(GPU_RCS) -o $(GPU_TARGET)

run:
	./$(GPU_TARGET) > test.log 2>&1

clean:
	rm -rf bench* buffer* message_record.txt
	rm -rf _app_cuda_version_* _cuobjdump_list_ptx_* gpgpusim_power_report_* *.ptx *.ptxas gpgpusim.*.log gpgpu_inst_stats.txt
	rm -rf sim.cfg sim.info sim.out sim.stats.sqlite3
	rm -rf checkpoint_files
cleanall:
	make clean
	rm -rf tran_cu