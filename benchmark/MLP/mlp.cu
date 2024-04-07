#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <sys/time.h>
#include <stdio.h>
#include <math.h>
#include <string>
#include <iostream>
#include <fstream>
#include <iostream>
#define BLOCK_DIM 10 


__global__ void matrix_mul_gpu(int64_t *M, int64_t* N, int64_t* P, int64_t widthA, int64_t heightA, int64_t widthB)
{
    int64_t i = threadIdx.x + blockDim.x * blockIdx.x;
    int64_t j = threadIdx.y + blockDim.y * blockIdx.y;
    if (i < widthB && j < heightA) {
        int64_t sum = 0;
        for (int64_t k = 0; k < widthA; k++) {
            int64_t a = M[j * widthA + k];
            int64_t b = N[k * widthB + i];
            sum += a * b;
        }
        P[j * widthB + i] = sum;
    }
}

/**
 * 用于传递单个chiplet计算结果的kernel函数
 */
__global__ void passMessage(int64_t srcX,int64_t srcY,int64_t dstX, int64_t dstY, int64_t* data, int64_t dataSize){
	int64_t para1 = srcX *10000000 + srcY*100000 + dstX*1000+dstY * 10 ;
	for(int64_t i = 0; i<dataSize;i++){
		asm("addc.s64 %0, %1, %2;" : "=l"(data[i]) : "l"(para1) , "l"(data[i]));
	}
}

__global__ void readMessage(int64_t srcX,int64_t srcY,int64_t dstX, int64_t dstY, int64_t* data, int64_t dataSize)
{
	int64_t para1 = srcX *10000000 + srcY*100000 + dstX*1000+dstY * 10 + 1 ;
	for(int64_t i = 0; i<dataSize;i++){
		data[i]=i;
		asm("addc.s64 %0, %1, %2;" : "=l"(data[i]) : "l"(para1) , "l"(data[i]));
	}
}

void mkfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./cpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
	FILE *file=fopen(fileName,"w");
	if(file!=NULL) std::cout<<fileName<<"创建成功"<<std::endl;
	fclose(file);
}

bool checkfile(char* fileName){
	FILE *file=fopen(fileName,"r");
	if(file==NULL){
		return 0;
	}
	else{
		return 1;
	}
}

void delfile(char* fileName){
	if(remove(fileName)==0){
		printf("文件 \"%s\" 已成功删除。\n", fileName);
	}
}
int Row_A=0,Col_A=0,Row_B=0,Col_B=0;
int main(int argc, char** argv)
{
	char* filename=new char[100];
	sprintf(filename,"start running");
	while(checkfile(filename)){
		char* fileName=new char[100];
		//读取本进程所代表的chiplet编号
		int srcX=atoi(argv[1]);
		int srcY=atoi(argv[2]);
		int64_t *size_A=new int64_t [2];
		int64_t *size_B=new int64_t [2];
		int64_t *Size_A,*Size_B;
		cudaMalloc((void**)&Size_A, sizeof(int64_t) *2);
		cudaMalloc((void**)&Size_B, sizeof(int64_t) *2);
		
		sprintf(fileName,"./gpuRead1%d_%d_%d_%d",0,0,srcX,srcY);
		bool file=0;
		while(file==0){
			file=checkfile(fileName);
		}
		readMessage <<<1,1>>> (0,0,srcX,srcY,Size_A,2);
		readMessage <<<1,1>>> (0,0,srcX,srcY,Size_B,2);
		sprintf(fileName,"./gpuRead1%d_%d_%d_%d",0,0,srcX,srcY);
		delfile(fileName);
		cudaMemcpy(size_A, Size_A, sizeof(int64_t) * 2, cudaMemcpyDeviceToHost);
		cudaMemcpy(size_B, Size_B, sizeof(int64_t) * 2, cudaMemcpyDeviceToHost);
		Row_A=size_A[0];Col_A=size_A[1];
		Row_B=size_B[0];Col_B=size_B[1];
		int64_t *C = (int64_t *)malloc(sizeof(int64_t) * Col_B*Row_A);
		int64_t *A = (int64_t *)malloc(sizeof(int64_t) * Row_A * Col_A);
		printf("A:%d %d\n",Row_A,Col_A);
		printf("B:%d %d\n",Row_B,Col_B);
		int64_t *d_dataA, *d_dataB, *d_dataC;
		cudaMalloc((void**)&d_dataA, sizeof(int64_t) *Row_A*Col_A);
		cudaMalloc((void**)&d_dataB, sizeof(int64_t) *Row_B*Col_B);
		cudaMalloc((void**)&d_dataC, sizeof(int64_t) *Col_B*Row_A);
	
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		file=0;
		sprintf(fileName,"./gpuRead%d_%d_%d_%d",0,0,srcX,srcY);
		while(file==0){
			file=checkfile(fileName);
		}
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		delfile(fileName);
		readMessage <<<1,1>>> (0,0,srcX,srcY,d_dataA,Col_A*Row_A);
		readMessage <<<1,1>>> (0,0,srcX,srcY,d_dataB,Col_B*Row_B);
		// sprintf(fileName,"./buffer%d_%d_%d_%d",0,0,srcX,srcY);
		// delfile(fileName);
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		cudaMemcpy(A, d_dataA, sizeof(int64_t) * Col_A * Row_A, cudaMemcpyDeviceToHost);
		for(int64_t i=0;i<Row_A * Col_A;i++){
			std::cout<<A[i];
			if(i%Col_A==0 && i!=0)std::cout<<std::endl;
			else std::cout<<" ";
		}
		//calculate
		dim3 threadPerBlock(BLOCK_DIM,BLOCK_DIM);
		//dim3 blockNumber(1);
		dim3 blockNumber((Col_B + threadPerBlock.x - 1) / threadPerBlock.x, (Row_A + threadPerBlock.y - 1) / threadPerBlock.y);
		matrix_mul_gpu << <blockNumber, threadPerBlock >> > (d_dataA, d_dataB, d_dataC,Col_A,Row_A,Col_B);
		cudaMemcpy(C, d_dataC, sizeof(int64_t) * Row_A * Col_B, cudaMemcpyDeviceToHost);
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		for(int64_t i=0;i<Row_A * Col_B;i++){
			std::cout<<C[i];
			if(i%Col_B==0 && i!=0)std::cout<<std::endl;
			else std::cout<<" ";
		}
		passMessage << <1,1>> > (srcX,srcY,0,0,d_dataC,Row_A * Col_B);
		mkfile(srcX,srcY,0,0);
		cudaFree(d_dataA);
		cudaFree(d_dataB);
		cudaFree(d_dataC);
		
		delete fileName;
	}
	delete filename;
	return 0;
}
