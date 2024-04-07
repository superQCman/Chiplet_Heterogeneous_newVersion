#include <fstream>
#include <iostream>
#include "interchiplet_app.h"
#define Row 100
#define Col 100

int srcX,srcY;

using namespace std;

using namespace nsInterchiplet;
void mkfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./gpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
	FILE *file=fopen(fileName,"w");
	if(file!=NULL) std::cout<<fileName<<"创建成功"<<std::endl;
	fclose(file);
	delete fileName;
}
bool checkfile(int srcX,int srcY,int dstX,int dstY){
	char* fileName=new char[100];
	sprintf(fileName,"./cpuRead%d_%d_%d_%d",srcX,srcY,dstX,dstY);
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
int main(int argc, char** argv)
{
    srcX=atoi(argv[1]);
    srcY=atoi(argv[2]);

    double *A = (double *)malloc(sizeof(double) * Row * Col);
    double *B = (double *)malloc(sizeof(double) * Row * Col);
    double *C1 = (double *)malloc(sizeof(double) * Row * Col);
    // int64_t *C2 = (int64_t *)malloc(sizeof(int64_t) * Row * Col);
    // int64_t *C3 = (int64_t *)malloc(sizeof(int64_t) * Row * Col);

    for (int i = 0; i < Row*Col; i++) {
        A[i] = 1.5;
        B[i] = 1.5;
	//std::cout<<A[i]<<' ';
    }

    std::cout<<"aaa"<<endl;
    sendGpuMessage(0,1,srcX,srcY,A,Row * Col);
    sendGpuMessage(0,1,srcX,srcY,B,Row * Col);
    mkfile(srcX,srcY,0,1);
    bool file=0;
    while(file==0)
        file=checkfile(0,1,srcX,srcY);
    delfile(srcX,srcY,0,1);
    readGpuMessage(0,1,srcX,srcY,C1,Row * Col);
    std::cout<<"eee"<<endl;
}