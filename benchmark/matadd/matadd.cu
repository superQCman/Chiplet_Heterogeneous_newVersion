#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <sys/time.h>
#include <stdio.h>
#include <math.h>
#include <string>
#include <iostream>
#include <fstream>
#include <iostream>
#define Row 100
#define Col 100
__global__ void matrix_add_gpu(double *M, double* N, double* P, int width)
{
	int i = threadIdx.x + blockDim.x * blockIdx.x;//下标0是数组长度
	int j = threadIdx.y + blockDim.y * blockIdx.y;
	int sumNum = j*width + i;
	P[sumNum] = M[sumNum]+N[sumNum];
}

void mkfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./cpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
	FILE *file=fopen(fileName,"w");
	if(file!=NULL) std::cout<<fileName<<"创建成功"<<std::endl;
	fclose(file);
	delete fileName;
}

bool checkfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./gpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
	FILE *file=fopen(fileName,"r");
	delete fileName;
	if(file==NULL)return 0;
	else return 1;
}

void delfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./gpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
	if(remove(fileName)==0){
		printf("文件 \"%s\" 已成功删除。\n", fileName);
	}
	delete fileName;
}
__global__ void passMessage(int srcX,int srcY,int dstX, int dstY, double* data, int dataSize){
	int64_t para1 = srcX *10000000 + srcY*100000 + dstX*1000+dstY * 10 ;
	// float* Data=reinterpret_cast<float*>(data);
	for(int i = 0; i<dataSize;i++){
		asm("addc.s64 %0, %1, %2;" : "=d"(data[i]) : "d"(para1) , "d"(data[i]));
	}
}

__global__ void readMessage(int srcX,int srcY,int dstX, int dstY, double* data, int dataSize)
{
	int64_t para1 = srcX *10000000 + srcY*100000 + dstX*1000+dstY * 10 + 1 ;
	for(int i = 0; i<dataSize;i++){
		data[i]=i;
		asm("addc.s64 %0, %1, %2;" : "=l"(data[i]) : "l"(para1) , "l"(data[i]));
	}
}

int main(int argc, char** argv)
{
	//读取本进程所代表的chiplet编号
	double *C = (double *)malloc(sizeof(double) * (Col*Row));
	double *A = (double *)malloc(sizeof(double) * (Row * Col));
	int srcX=atoi(argv[1]);
	int srcY=atoi(argv[2]);
	double *d_dataA, *d_dataB, *d_dataC;
	cudaMalloc((void**)&d_dataA, sizeof(double) *(Row*Col));
	cudaMalloc((void**)&d_dataB, sizeof(double) *(Row*Col));
	cudaMalloc((void**)&d_dataC, sizeof(double) *Col*Row);
	bool file=0;
	while(file==0){
		file=checkfile(0,0,srcX,srcY);
	}
	//delfile(0,0,srcX,srcY);
	readMessage <<<1,1>>> (0,0,srcX,srcY,d_dataA,Row*Col);
	readMessage <<<1,1>>> (0,0,srcX,srcY,d_dataB,Row*Col);
	std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
	cudaMemcpy(A, d_dataA, sizeof(int) * (Col * Row), cudaMemcpyDeviceToHost);
	for(int i=0;i< Row*Col;i++){
		std::cout<<A[i];
		if(i%Col==0 && i!=0)std::cout<<std::endl;
		else std::cout<<" ";
	}
	//calculate
	dim3 threadPerBlock(10,10);
	//dim3 blockNumber(1);
	dim3 blockNumber((Col + threadPerBlock.x - 1) / threadPerBlock.x, (Row + threadPerBlock.y - 1) / threadPerBlock.y);
	matrix_add_gpu << <blockNumber, threadPerBlock >> > (d_dataA, d_dataB, d_dataC, Col);
	cudaMemcpy(C, d_dataC, sizeof(int) * (Row * Col), cudaMemcpyDeviceToHost);
	std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
	for(int i=0;i<Row*Col;i++){
		std::cout<<C[i];
		if(i%Col==0 && i!=0)std::cout<<std::endl;
		else std::cout<<" ";
	}
	passMessage << <1,1>> > (srcX,srcY,0,0,d_dataC,Row*Col);
	mkfile(srcX,srcY,0,0);
	cudaFree(d_dataA);
	cudaFree(d_dataB);
	cudaFree(d_dataC);
	return 0;
}
