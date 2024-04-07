#include<stdio.h>
#include<iostream>
#include<cuda_runtime.h>
#define ROW 10
#define COL 12
#define BLOCK_DIM 16

__global__ void transpose_GPU_(int64_t* d_odata, int64_t* d_idata, int width, int height) {
    __shared__ int64_t block[BLOCK_DIM][BLOCK_DIM + 1]; // Adding +1 to avoid shared memory bank conflicts
    int xIndex = threadIdx.x + blockDim.x * blockIdx.x;
    int yIndex = threadIdx.y + blockDim.y * blockIdx.y;

    if (xIndex < width && yIndex < height) {
        int index_in = xIndex + yIndex * width;
        block[threadIdx.y][threadIdx.x] = d_idata[index_in];
    }

    __syncthreads();

    xIndex = blockIdx.y * blockDim.y + threadIdx.x;
    yIndex = blockIdx.x * blockDim.x + threadIdx.y;

    if (xIndex < height && yIndex < width) { // Notice the swapped conditions
        int index_out = xIndex + yIndex * height; // Correctly calculating index_out considering the transposed dimensions
        d_odata[index_out] = block[threadIdx.x][threadIdx.y];
    }
}


int main(){
    int size=ROW*COL;
    int64_t *h_a=new int64_t[size];
    int64_t *h_b=new int64_t[size];
// std::cout<<"###################################################################"<<std::endl;
    for(int i=0;i<size;i++){
        h_a[i]=rand()%51;
        std::cout<<h_a[i]<<" ";
        if((i+1)%COL==0&& i!=0) std::cout<<std::endl;
    }
    std::cout<<"###################################################################"<<std::endl;
    int64_t *d_a,*d_b;
    cudaMalloc((void**)&d_a,sizeof(int64_t)*size);
    cudaMalloc((void**)&d_b,sizeof(int64_t)*size);
    cudaMemcpy(d_a,h_a,sizeof(int64_t)*size,cudaMemcpyHostToDevice);
    dim3 threadPerblock(BLOCK_DIM,BLOCK_DIM);
    dim3 blockPergride((COL+BLOCK_DIM-1)/BLOCK_DIM,(ROW+BLOCK_DIM-1)/BLOCK_DIM);
    transpose_GPU_<<<blockPergride,threadPerblock>>>(d_b,d_a,COL,ROW);
    cudaMemcpy(h_b,d_b,sizeof(int64_t)*size,cudaMemcpyDeviceToHost);
    std::cout<<"###################################################################翻转矩阵"<<std::endl;
    for(int i=0;i<size;i++){
        std::cout<<h_b[i]<<" ";
        if((i+1)%ROW==0 && i!=0) std::cout<<std::endl;
    }
    free(h_a);
    free(h_b);
    cudaFree(d_b);
    cudaFree(d_a);
    return 0;
}