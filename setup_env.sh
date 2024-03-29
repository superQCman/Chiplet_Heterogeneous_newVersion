export PATH=$PATH:/usr/local/cuda-11.1/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-11.1/lib:/usr/local/cuda-11.1/lib64
export CUDA_INSTALL_PATH=/usr/local/cuda-11.1
export SIMULATOR_ROOT="$(pwd)"

source gpgpu-sim/setup_environment
