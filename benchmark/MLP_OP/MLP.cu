#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <sys/time.h>
#include <stdio.h>
#include <math.h>
#include <string>
#include <iostream>
#include <fstream>
#include <iostream>
#include<vector>
#include <c++/11/bits/algorithmfwd.h>
#include <thread>
#define BLOCK_DIM 10 


__global__ void transpose_GPU_(double* d_odata, double* d_idata, int width, int height) {
    __shared__ double block[BLOCK_DIM][BLOCK_DIM + 1]; // Adding +1 to avoid shared memory bank conflicts
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

__global__ void matrix_mul_gpu(double *M, double* N, double* P, int64_t widthA, int64_t heightA, int64_t widthB)
{
    int64_t i = threadIdx.x + blockDim.x * blockIdx.x;
    int64_t j = threadIdx.y + blockDim.y * blockIdx.y;
    if (i < widthB && j < heightA) {
        double sum = 0;
        for (int64_t k = 0; k < widthA; k++) {
            double a = M[j * widthA + k];
            double b = N[k * widthB + i];
            sum += a * b;
        }
        P[j * widthB + i] = sum;
    }
}

__global__ void applyActivationFunction(double* y, int width){
    int i=threadIdx.x+blockDim.x*blockIdx.x;
    int j=threadIdx.y+blockDim.y*blockIdx.y;
    y[j*width+i]=max(0.0,y[j*width+i]);
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

void ReadMatrix(int64_t *A,int64_t *d_dataA, char* fileName,int srcX,int srcY,int Row_A,int Col_A){
		cudaMalloc((void**)&d_dataA, sizeof(int64_t) *Row_A*Col_A);
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		bool file=0;
		sprintf(fileName,"./gpuRead%d_%d_%d_%d",0,0,srcX,srcY);
		while(file==0){
			file=checkfile(fileName);
		}
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		delfile(fileName);
		readMessage <<<1,1>>> (0,0,srcX,srcY,d_dataA,Col_A*Row_A);

		// sprintf(fileName,"./buffer%d_%d_%d_%d",0,0,srcX,srcY);
		// delfile(fileName);
		std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
		cudaMemcpy(A, d_dataA, sizeof(int64_t) * Col_A * Row_A, cudaMemcpyDeviceToHost);
		for(int64_t i=0;i<Row_A * Col_A;i++){
			std::cout<<A[i];
			if(i%Col_A==0 && i!=0)std::cout<<std::endl;
			else std::cout<<" ";
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

int input_size=0;std::vector<int> hidden_size;int output_size=0;
std::vector<std::vector<std::vector<double>>> weight,biases;std::vector<int>layer_sizes;
std::vector<std::vector<std::vector<double>>> zs,activations;


std::vector<std::vector<double>> doubleToVector(std::vector<std::vector<double>> V,double* weight_i){
    for(size_t i=0;i<V.size();i++){
        // std::vector<double> temp;
        for(size_t j=0;j<V[i].size();j++){
            V[i][j]=(weight_i[j+i*V[0].size()]);
        }
        // V.push_back(temp);
    }
    return V;
}

void vectorToDouble(std::vector<std::vector<double>> V,double* weight_i){
    for(size_t i=0;i<V.size();i++){
        for(size_t j=0;j<V[i].size();j++){
            weight_i[j+i*V[0].size()]=V[i][j];
        }
    }
}

void DoubleToInt(double* mat1,int64_t *mat2,int size){
    int64_t time=std::pow(10,8);
    for(int i=0;i<size;i++){
        mat2[i]=mat1[i]*time;
    }
}
void IntToDouble(double* mat1,int64_t *mat2,int size){
    double time=std::pow(10,16);
    for(int i=0;i<size;i++){
        mat1[i]=mat2[i]/time;
    }
}

std::vector<std::vector<double>> activate_function(std::vector<std::vector<double>> x){
    for(size_t i=0;i<x.size();i++){
        for(size_t j = 0;j<x[i].size();j++){
            if(x[i][j]<=0) x[i][j]=0.01*x[i][j];
        }
    }
    return x;
}

std::vector<std::vector<double>> activate_function_derivative(std::vector<std::vector<double>> x){
    for(size_t i=0;i<x.size();i++){
        for(size_t j=0;j<x[i].size();j++){
            if(x[i][j]<=0) x[i][j]=0.01;
            else x[i][j]=1;
        }
    }
    return x;
}

// void T(double* a,std::vector<std::vector<double>> x,int Row,int Col){
//     for(int j=0;j<Col;j++){
//         for(int i=0;i<Row;i++){
//             a[i+j*Row]=x[i][j];
//             a1[j][i]=x[i][j];
//         }
//     }
// }

// void T2(double* a,std::vector<std::vector<double>> x,int Row,int Col){
//     for(int j=0;j<Col;j++){
//         for(int i=0;i<Row;i++){
//             a[i+j*Row]=x[i][j];
//         }
//     }
//     // vectorToDouble(x,a);
//     // Transpose_GPU(a,x.size(),x[0].size());
// }

double c_norm(const std::vector<std::vector<double>>& vec) {
    double sum_of_squares = 0.0;
    for (const auto& row : vec) {
        for (double x : row) {
            sum_of_squares += x * x;
        }
    }
    return std::sqrt(sum_of_squares);
}

void MUL(double*  d_dataA,double* d_dataB,int fst_Row,int fst_Col,int sec_Row,int sec_Col,std::vector<std::vector<double>>& Res){
    double *d_dataC;
	cudaMalloc((void**)&d_dataA,sizeof(double)*fst_Row*fst_Col);
	cudaMalloc((void**)&d_dataB,sizeof(double)*sec_Row*sec_Col);
	cudaMalloc((void**)&d_dataC,sizeof(double)*fst_Row*sec_Col);
	double *C = (double *)malloc(sizeof(double) * sec_Col*fst_Row);
	dim3 threadPerBlock(BLOCK_DIM,BLOCK_DIM);
	//dim3 blockNumber(1);
	dim3 blockNumber((sec_Col + threadPerBlock.x - 1) / threadPerBlock.x, (fst_Row + threadPerBlock.y - 1) / threadPerBlock.y);
	matrix_mul_gpu << <blockNumber, threadPerBlock >> > (d_dataA, d_dataB, d_dataC,fst_Col,fst_Row,sec_Col);
	cudaMemcpy(C, d_dataC, sizeof(double) * fst_Row * sec_Col, cudaMemcpyDeviceToHost);
	std::cout<<"################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&矩阵计算结果################################################&&&&&&&&&&&&&&&&&&&&&&&&&&&&\n";
	std::vector<double> temp_res;
	for(int64_t i=0;i<fst_Row * sec_Col;i++){
		std::cout<<C[i];
        temp_res.push_back(C[i]);
		if(i%sec_Col==0 && i!=0){
			std::cout<<std::endl;
			Res.push_back(temp_res);
			temp_res.clear();
		}
		else{
			std::cout<<" ";
		}
	}
    delete []C;
}

void Transpos(double* d_data,int Row,int Col,double* ans){
    cudaMalloc((void**)&d_data,sizeof(double)*Row*Col);
    double *Ans;
    cudaMalloc((void**)&Ans,sizeof(double)*Row*Col);
    dim3 threadPerBlock(BLOCK_DIM,BLOCK_DIM);
    dim3 blockNumber((Col+threadPerBlock.x-1)/threadPerBlock.x,(Row+threadPerBlock.y-1)/threadPerBlock.y);
    transpose_GPU_<<<blockNumber,threadPerBlock>>>(Ans,d_data,Col,Row);
    cudaMemcpy(ans,Ans,sizeof(double)*Row*Col,cudaMemcpyDeviceToHost);
    delete []ans;
}

//gpu_num=-1为转置
void ToGPU(double*  d_dataA,double* d_dataB,int fst_Row,int fst_Col,int sec_Row,int sec_Col,std::vector<std::vector<double>>& Res,double* res,int gpu_num){
	if(gpu_num>0){
        MUL(d_dataA,d_dataB,fst_Row,fst_Col,sec_Row,sec_Col,Res);
    }else if(gpu_num==-1){
        Transpos(d_dataA,fst_Row,fst_Col,res);
    }
}

// 计算二维向量沿着指定轴的和，并保持维度
std::vector<std::vector<double>> sum_axis(const std::vector<std::vector<double>>& vec, int axis,int m) {
    std::vector<std::vector<double>> result;
    
    if (axis == 0) {
        for (size_t j = 0; j < vec[0].size(); ++j) {
            double sum = 0.0;
            for (size_t i = 0; i < vec.size(); ++i) {
                sum += vec[i][j];
            }
            result.push_back({sum/m});
        }
    } else if (axis == 1) {
        for (const auto& row : vec) {
            double sum = 0.0;
            for (double x : row) {
                sum += x;
            }
            result.push_back({sum/m});
        }
    }
    return result;
}
std::vector<std::vector<double>> forward(std::vector<std::vector<double>>& x){
    int Row=x.size();
    int Col=x[0].size();
    std::cout<<"#############################################"<<std::endl;
    double *A=new double [Col*Row];
    std::vector<std::vector<double>> a1(Col,std::vector<double>(Row));
    double *X;
    vectorToDouble(x,X);
    ToGPU(X,NULL,Row,Col,0,0,a1,A,-1);
    a1=doubleToVector(a1,A);
    std::cout<<"#############################################"<<std::endl;
    activations.push_back(a1);
    for(size_t i=0;i<weight.size();i++){
        double *Weight=new double [weight[i].size()*weight[i][0].size()];
        vectorToDouble(weight[i],Weight);
        std::vector<std::vector<double>> DotRns;
        ToGPU(Weight,A,weight[i].size(),weight[i][0].size(),Col,Row,DotRns,NULL,1);
        std::cout<<"#############################################"<<std::endl;
        for(size_t m=0;m<DotRns.size();m++){
            for(size_t n=0;n<DotRns[m].size();n++){
                DotRns[m][n]+=biases[i][m][0];
            }
        }
        std::vector<std::vector<double>> z=DotRns;
        a1=activate_function(z);
        vectorToDouble(a1,A);
        Col=a1.size();Row=a1[0].size();
        zs.push_back(z);
        activations.push_back(a1);
        delete[] Weight;
        Weight=NULL;
    }
    delete[] A;
    return a1;
}

void backward(std::vector<std::vector<double>> x, std::vector<std::vector<double>>& y,double learning_rate,std::vector<std::vector<double>>&y_hat){
    int m=x.size(); //获取第一个维度大小
    //std::vector<std::vector<double>> y_hat = activations[activations.size()-1];
    double* a = new double [y.size()*y[0].size()];
    std::vector<std::vector<double>> A;
    int Row=y.size();int Col=y[0].size();
    // T2(a,y,Row,Col);
    double *Y=new double[y.size()*y[0].size()];
    vectorToDouble(y,Y);
    ToGPU(Y,NULL,y.size(),y[0].size(),0,0,A,a,-1);

    std::vector<std::vector<std::vector<double>>> deltas; //用于存储每一层的误差项
    std::vector<std::vector<double>> d_temp;
    for(size_t i=0;i<y_hat.size();i++){
        std::vector<double> temp;
        for(size_t j=0;j<y_hat[i].size();j++){
            temp.push_back(y_hat[i][j]-a[i*y_hat[i].size()+j]);
        }
        d_temp.push_back(temp);
    }
    deltas.push_back(d_temp);

    std::vector<std::vector<std::vector<double>>> grads_weights,grads_biases;
    for(int i=weight.size()-1;i>=0;i--){

        std::vector<std::vector<double>> act_F=activate_function_derivative(zs[i]);
        std::vector<std::vector<double>> dz(act_F.size(),std::vector<double>(act_F[0].size()));
        for(size_t m=0;m<act_F.size();m++){
            for(size_t n=0;n<act_F[m].size();n++){
                dz[m][n]=act_F[m][n]*deltas[deltas.size()-1][m][n];
            }
        }
        
        int max_grad_norm=10; //设置梯度的最大范数
        double norm=c_norm(dz);
        if(norm>max_grad_norm){
            for(size_t i=0;i<dz.size();i++){
                for(size_t j=0;j<dz[i].size();j++){
                    dz[i][j]*=max_grad_norm/norm;
                }
            }
        }

        double *Dz=new double[dz.size()*dz[0].size()];
        vectorToDouble(dz,Dz);
        double* Activations_i=new double[activations[i].size()*activations[i][0].size()];
        //T2(Activations_i,activations[i],activations[i].size(),activations[i][0].size());
        vectorToDouble(activations[i],Activations_i);
        double* Activations_i_T=new double[activations[i].size()*activations[i][0].size()];
        ToGPU(Activations_i,nullptr,activations[i].size(),activations[i][0].size(),0,0,activations[i],Activations_i_T,-1);

        double *Weight=new double [weight[i].size()*weight[i][0].size()];
        // T2(Weight,weight[i],weight[i].size(),weight[i][0].size());
        vectorToDouble(weight[i],Weight);
        double* Weight_T=new double[weight[i].size()*weight[i][0].size()];
        ToGPU(Weight,NULL,weight[i].size(),weight[i][0].size(),0,0,weight[i],Weight_T,-1);


        std::vector<std::vector<double>> deltas_pre;
        std::vector<std::vector<double>> dw;
        std::thread t1(ToGPU,Weight_T,Dz,weight[i][0].size(),weight[i].size(),dz.size(),dz[0].size(),std::ref(deltas_pre),NULL,1);
        //GpuMultiply(Weight,Dz,weight[i][0].size(),weight[i].size(),dz.size(),dz[0].size(),std::ref(deltas_pre),1);
        std::thread t2 (ToGPU,Dz,Activations_i_T,dz.size(),dz[0].size(),activations[i][0].size(),activations[i].size(),std::ref(dw),NULL,2);
        std::cout<<"***********************************************************************************"<<i<<std::endl;
        // GpuMultiply(Dz,Activations_i,dz.size(),dz[0].size(),activations[i][0].size(),activations[i].size(),std::ref(dw),1);
        t1.join();
        t2.join();
        deltas.push_back(deltas_pre);
        for(size_t i=0;i<dw.size();i++){
            for(size_t j=0;j<dw[i].size();j++){
                dw[i][j]*=1/m;
            }
        }

        delete[] Activations_i;delete[] Activations_i_T;
        Activations_i=NULL;
        std::vector<std::vector<double>> db=sum_axis(dz,1,m);
        grads_weights.push_back(dw);
        grads_biases.push_back(db);
        delete[] Weight;delete[] Dz;delete[] Weight_T;
        Weight=NULL;Dz=NULL;
    }
    std::reverse(grads_weights.begin(),grads_weights.end());
    std::reverse(grads_biases.begin(),grads_biases.end());

    //跟新权重和偏置值
    for(size_t i=0;i<weight.size();i++){
        for(size_t j=0;j<weight[i].size();j++){
            for(size_t k=0;k<weight[i][j].size();k++){
                weight[i][j][k]-=learning_rate*grads_weights[i][j][k];
            }
        }
    }
    for(size_t i=0;i<biases.size();i++){
        for(size_t j=0;j<biases[i].size();j++){
            for(size_t k=0;k<biases[i][j].size();k++){
                biases[i][j][k]-=learning_rate*grads_biases[i][j][k];
            }
        }
    }
}
std::vector<std::vector<double>> Read(char* fileName,int srcX,int srcY);
void train(std::vector<std::vector<double>>& x,std::vector<std::vector<double>> y,int srcX,int srcY,int num_iterations=1000,double learning_rate=0.1){
    for(int i=0;i<num_iterations;i++){
        std::vector<std::vector<double>> y_predict=forward(x);
        //计算损失值并传给CPU
        double *Y_predict=new double[y_predict.size()*y_predict[0].size()];
        int64_t *Y_predict_int=new int64_t[y_predict.size()*y_predict[0].size()];
        vectorToDouble(y_predict,Y_predict);
        DoubleToInt(Y_predict,Y_predict_int,y_predict.size()*y_predict[0].size());
        int64_t *Y_send;
        cudaMalloc((void**)&Y_send,sizeof(int64_t)*y_predict.size()*y_predict[0].size());
        cudaMemcpy(Y_send,Y_predict_int,sizeof(int64_t)*y_predict.size()*y_predict[0].size(),cudaMemcpyHostToDevice);
        passMessage << <1,1>> > (srcX,srcY,0,0,Y_send,y_predict.size()*y_predict[0].size());
        mkfile(srcX,srcY,0,0);
        char* fileName=new char[100];
	    sprintf(fileName,"./back");
        bool file=0;
		while(file==0){
			file=checkfile(fileName);
		}
        std::vector<std::vector<double>>y_hat=Read(fileName,srcX,srcY);
        //反传
        backward(x,y,learning_rate,y_hat);
    }
}

std::vector<std::vector<double>> Read(char* fileName,int srcX,int srcY){
    int64_t *size_A=new int64_t [2];
    int64_t *Size_A;
    cudaMalloc((void**)&Size_A, sizeof(int64_t) *2);
    sprintf(fileName,"./gpuRead_%d_%d_%d_%d_%d",NUM++,0,0,srcX,srcY);
    bool file=0;
    while(file==0){
        file=checkfile(fileName);
    }
    readMessage <<<1,1>>> (0,0,srcX,srcY,Size_A,2);
    delfile(fileName);
    cudaMemcpy(size_A, Size_A, sizeof(int64_t) * 2, cudaMemcpyDeviceToHost);
    
    int Row_A=size_A[0];int Col_A=size_A[1];
    
    // int64_t *C = (int64_t *)malloc(sizeof(int64_t) * Col_B*Row_A);
    int64_t *A = (int64_t *)malloc(sizeof(int64_t) * Row_A * Col_A);
    printf("A:%d %d\n",Row_A,Col_A);
    int64_t *d_dataA;double* D_dataA;
    ReadMatrix(A,d_dataA,fileName,srcX,srcY,Row_A,Col_A);
    IntToDouble(D_dataA,d_dataA,Row_A * Col_A);
    std::vector<std::vector<double>> x_train(Row_A,std::vector<double>(Col_A));
    x_train=doubleToVector(x_train,D_dataA);
	delete []A;
    delete []size_A;
    cudaFree(Size_A);
    return x_train;
}

int NUM=0;
int main(int argc, char** argv)
{
	char* filename=new char[100];
	sprintf(filename,"start running");
	while(checkfile(filename)){
		char* fileName=new char[100];
		//读取本进程所代表的chiplet编号
		int srcX=atoi(argv[1]);
		int srcY=atoi(argv[2]);
        //读取输入矩阵数据
		std::vector<std::vector<double>> x_train;
        x_train=Read(fileName,srcX,srcY);
        std::vector<std::vector<double>> y_train;
        y_train=Read(fileName,srcX,srcY);

        //读取输入层和输出层神经元个数以及隐层层数
        int64_t *size_layer=new int64_t [3];
        int64_t *Size_layer;
        cudaMalloc((void**)&Size_layer, sizeof(int64_t) *3);
        sprintf(fileName,"./gpuRead_%d_%d_%d_%d_%d",NUM++,0,0,srcX,srcY);
		bool file=0;
		while(file==0){
			file=checkfile(fileName);
		}
        delfile(fileName);
        readMessage <<<1,1>>> (0,0,srcX,srcY,Size_layer,3);
        int hidden_layer;
        cudaMemcpy(size_layer, Size_layer, sizeof(int64_t) * 3, cudaMemcpyDeviceToHost);
        input_size=size_layer[0];
        hidden_layer=size_layer[1];
        output_size=size_layer[2];
        //读取隐藏层神经元个数
        int64_t *size_hidden=new int64_t [hidden_layer];
        int64_t *Size_hidden;
        cudaMalloc((void**)&Size_hidden,sizeof(int64_t)*hidden_layer);
        sprintf(fileName,"./gpuRead_%d_%d_%d_%d_%d",NUM++,0,0,srcX,srcY);
		file=0;
		while(file==0){
			file=checkfile(fileName);
		}
        delfile(fileName);
        readMessage <<<1,1>>> (0,0,srcX,srcY,Size_hidden,hidden_layer);
		std::vector<int64_t*>layer_matrix;
        std::vector<double*>Layer_matrix;
		layer_sizes.push_back(input_size);
		for(int i=0;i<hidden_layer;i++){
			layer_sizes.push_back(Size_hidden[i]);
			hidden_size.push_back(Size_hidden[i]);
			layer_matrix.push_back(NULL);
		}
        layer_sizes.push_back(output_size);
		//获取权重矩阵
		for(int i=0;i<layer_sizes.size()-1;i++){
			sprintf(fileName,"./gpuRead_%d_%d_%d_%d_%d",NUM++,0,0,srcX,srcY);
			file=0;
			while(file==0){
				file=checkfile(fileName);
			}
        	delfile(fileName);
			int64_t *A = (int64_t *)malloc(sizeof(int64_t) * layer_sizes[i] * layer_sizes[i+1]);
			ReadMatrix(A,layer_matrix[i],fileName,srcX,srcY,layer_sizes[i+1],layer_sizes[i]);
            IntToDouble(Layer_matrix[i],layer_matrix[i],layer_sizes[i+1]*layer_sizes[i]);
			std::vector<std::vector<double>> temp1(layer_sizes[i+1],std::vector<double>(layer_sizes[i+1]));
			for(int j=0;j<layer_sizes[i+1];j++){
                temp1=doubleToVector(temp1,Layer_matrix[i]);
			}
			weight.push_back(temp1);
            delete []A;
		}
		//获取偏置矩阵
		for(int i=0;i<layer_sizes.size()-1;i++){
			sprintf(fileName,"./gpuRead_%d_%d_%d_%d_%d",NUM++,0,0,srcX,srcY);
			file=0;
			while(file==0){
				file=checkfile(fileName);
			}
        	delfile(fileName);
			int64_t *A = (int64_t *)malloc(sizeof(int64_t) * layer_sizes[i] * layer_sizes[i+1]);
			ReadMatrix(A,layer_matrix[i],fileName,srcX,srcY,layer_sizes[i+1],layer_sizes[i]);
			std::vector<std::vector<double>> temp1(layer_sizes[i+1],std::vector<double>(layer_sizes[i+1]));
			for(int j=0;j<layer_sizes[i+1];j++){
                temp1=doubleToVector(temp1,Layer_matrix[i]);
			}
			biases.push_back(temp1);
            delete []A;
		}

        train(x_train,y_train,srcX,srcY);
		
		
		delete fileName;
	}
	delete filename;
	return 0;
}
