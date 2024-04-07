#include <fstream>
#include <iostream>
#include "interchiplet_app.h"
#define Row 100
#define Col 100

int srcX,srcY;

using namespace std;

using namespace nsInterchiplet;

int main(int argc, char** argv)
{
    srcX=atoi(argv[1]);
    srcY=atoi(argv[2]);

    int64_t *A = (int64_t *)malloc(sizeof(int64_t) * Row * Col);
    int64_t *B = (int64_t *)malloc(sizeof(int64_t) * Row * Col);
    int64_t *C1 = (int64_t *)malloc(sizeof(int64_t) * Row * Col);
    int64_t *C2 = (int64_t *)malloc(sizeof(int64_t) * Row * Col);
    int64_t *C3 = (int64_t *)malloc(sizeof(int64_t) * Row * Col);

    for (int i = 0; i < Row*Col; i++) {
        A[i] = rand() % 51;
        B[i] = rand() % 51;
	//std::cout<<A[i]<<' ';
    }

    std::cout<<"aaa"<<endl;

<<<<<<< HEAD
    sendGpuMessage(0,1,srcX,srcY,A,Row * Col);
    sendGpuMessage(0,1,srcX,srcY,B,Row * Col);
    std::cout<<"bbb"<<endl;
    sendGpuMessage(1,0,srcX,srcY,A,Row * Col);
    sendGpuMessage(1,0,srcX,srcY,B,Row * Col);
    std::cout<<"ccc"<<endl;
    sendGpuMessage(1,1,srcX,srcY,A,Row * Col);
    sendGpuMessage(1,1,srcX,srcY,B,Row * Col);
    std::cout<<"ddd"<<endl;
    readGpuMessage(0,1,srcX,srcY,C1,Row * Col);
    std::cout<<"eee"<<endl;
    readGpuMessage(1,0,srcX,srcY,C2,Row * Col);
    std::cout<<"fff"<<endl;
    readGpuMessage(1,1,srcX,srcY,C3,Row * Col);
    std::cout<<"ggg"<<endl;
    std::cout<<"计算结果："<<std::endl;
    for(int i=0;i<Row * Col;i++)
=======
    sendGpuMessage(0,1,srcX,srcY,A,10000);
    sendGpuMessage(1,0,srcX,srcY,A,10000);
    sendGpuMessage(1,1,srcX,srcY,A,10000);

    sendGpuMessage(0,1,srcX,srcY,B,10000);
    sendGpuMessage(1,0,srcX,srcY,B,10000);
    sendGpuMessage(1,1,srcX,srcY,B,10000);

    readGpuMessage(srcX,srcY,0,1,C1,100);
    readGpuMessage(srcX,srcY,1,0,C2,100);
    readGpuMessage(srcX,srcY,1,1,C3,100);

    for(int i=0;i<100;i++)
>>>>>>> 273e8a9ed6591924adccb4d97578987480712ee4
    {
        C1[i] += C2[i];
        C1[i] += C3[i];
	    std::cout<<C1[i];
        if(i%Col==0 && i!=0)std::cout<<std::endl;
		else std::cout<<" ";
    }
}
