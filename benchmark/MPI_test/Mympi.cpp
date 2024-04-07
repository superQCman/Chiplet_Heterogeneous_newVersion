// #include<stdio.h>
// #include<iostream>
#include <mpi.h>

// int main(int argc, char *argv[]) {
//     int rank, size;
//     std::cout<<"test1"<<argc<<std::endl;
//     // 初始化MPI环境
//     MPI_Init(&argc, &argv);
//     std::cout<<"test2"<<std::endl;
//     MPI_Comm_rank(MPI_COMM_WORLD, &rank);
//     MPI_Comm_size(MPI_COMM_WORLD, &size);
//     std::cout<<"test2"<<std::endl;
//     // 获取当前通信器的通信组
//     MPI_Group group;
//     MPI_Comm_group(MPI_COMM_WORLD, &group);
//     std::cout<<"test3"<<std::endl;
//     // 在通信组中进行进程排名的集体操作
//     int group_rank;
//     MPI_Group_rank(group, &group_rank);
//     std::cout<<"test4"<<std::endl;
//     // 打印每个进程的通信组中的排名
//     printf("Rank %d has group rank %d\n", rank, group_rank);
    
//     // 释放通信组对象
//     MPI_Group_free(&group);
//     std::cout<<"test5"<<std::endl;
//     // 终止MPI环境
//     MPI_Finalize();
    
//     return 0;
// }
#include <stdio.h>
#include "mpi.h"

int main(int argc, char* argv[])
{
    int rank, size, len;
    char version[MPI_MAX_LIBRARY_VERSION_STRING];

    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    MPI_Get_library_version(version, &len);
    printf("Hello, world, I am %d of %d, (%s, %d)\n",
           rank, size, version, len);
    MPI_Finalize();

    return 0;
}
            