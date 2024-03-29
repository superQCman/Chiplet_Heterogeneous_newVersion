#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <sys/time.h>
#include <stdio.h>
#include <math.h>
#include <string>
#include <iostream>
#include <fstream>
#include <iostream>
#include <typeinfo>
using namespace std;


const int Row = 64; // 行数
const int Col = 64; // 列数

__global__
void matrix_mul_gpu(int *M, int* N, int* P, int width) // width代表列数
{
	int i = threadIdx.x + blockDim.x * blockIdx.x; // 第i列的线程
	int j = threadIdx.y + blockDim.y * blockIdx.y; // 第j行的线程
	
	int sum = 0;
	for (int k = 0; k < width; k++)
	{
		int a = M[j*width + k]; // 第j行的某一个值
		int b = N[k*width + i]; // 第i列的某一个值
		sum += a * b;
	}
	P[j*width + i] = sum;
	printf("P[j*width + i]:%d\n",blockIdx.x);
}

__global__
void matrix_add_gpu(int *M, int* N,int* P,int width){
	int i = threadIdx.x + blockDim.x * blockIdx.x; // 第i列的线程
	int j = threadIdx.y + blockDim.y * blockIdx.y; // 第j行的线程
	P[j*width + i] = M[j*width + i]+N[j*width + i];
}

void matrix_mul_cpu(int *M, int* N, int* P, int width)
{
	for (int i = 0; i < width; i++)
		for (int j = 0; j < width; j++)
		{
			int sum = 0.0;
			for (int k = 0; k < width; k++)
			{
				int a = M[i*width + k];
				int b = N[k*width + j];
				sum += a * b;
			}
			P[i*width + j] = sum;
		}
}

int main(int argc,char**argv)
{
	int AddOrMul=atoi(argv[1]);
	int *A = (int *)malloc(sizeof(int) * Row * Col);
	int *B = (int *)malloc(sizeof(int) * Row * Col);
	int *C = (int *)malloc(sizeof(int) * Row * Col);
	//malloc device memory
	int *d_dataA, *d_dataB, *d_dataC;
	cudaMalloc((void**)&d_dataA, sizeof(int) *Row*Col);
	cudaMalloc((void**)&d_dataB, sizeof(int) *Row*Col);
	cudaMalloc((void**)&d_dataC, sizeof(int) *Row*Col);
	//set value
	for (int i = 0; i < Row*Col; i++) {
		A[i] = 90;
		B[i] = 10;
	}

	cudaMemcpy(d_dataA, A, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
	cudaMemcpy(d_dataB, B, sizeof(int) * Row * Col, cudaMemcpyHostToDevice);
	dim3 threadPerBlock(16, 16);
	// (Col + threadPerBlock.x - 1)/threadPerBlock.x=Col/threadPerBlock.x+1，即多拿一个block来装不能整除的部分
	dim3 blockNumber((Col + threadPerBlock.x - 1) / threadPerBlock.x, (Row + threadPerBlock.y - 1) / threadPerBlock.y);
	printf("Block(%d,%d)   Grid(%d,%d).\n", threadPerBlock.x, threadPerBlock.y, blockNumber.x, blockNumber.y);
	// 每一个线程进行某行乘某列的计算，得到结果中的一个元素。也就是d_dataC中的每一个计算结果都和GPU中线程的布局<blockNumber, threadPerBlock >一致
	if (AddOrMul==1) matrix_mul_gpu << <blockNumber, threadPerBlock >> > (d_dataA, d_dataB, d_dataC, Col);
	else matrix_add_gpu << < blockNumber,threadPerBlock >> > (d_dataA,d_dataB,d_dataC,Col);
	//拷贝计算数据-一级数据指针
	cudaMemcpy(C, d_dataC, sizeof(int) * Row * Col, cudaMemcpyDeviceToHost);
	for(int i=0;i<Row * Col;i++){
		std::cout<<C[i];
		if(i%Col==0 && i!=0)std::cout<<std::endl;
		else std::cout<<" ";
	}
	//释放内存
	free(A);
	free(B);
	free(C);
	cudaFree(d_dataA);
	cudaFree(d_dataB);
	cudaFree(d_dataC);

	return 0;
}