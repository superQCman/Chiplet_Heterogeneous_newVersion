#include"interchiplet_app.h"

//#include"interchiplet_app_core.h"
#include"sniper_change.h"

#include<syscall.h>
#include<unistd.h>
#include<mutex>
#include<thread>
#include<iostream>

using namespace std;
using namespace nsChange;
namespace nsInterchiplet
{
    static mutex mtx;
    syscall_return_t sendGpuMessage(int64_t dstX,int64_t dstY,int64_t srcX,int64_t srcY,int64_t *a, int64_t size)
    {
        //std::cout<<a<<std::endl;
        int64_t a_=reinterpret_cast<int64_t>(a);
        int64_t *b=reinterpret_cast<int64_t*>(a_);
        //std::cout<<"转换前："<<a[1]<<std::endl;
        //for(int i = 0; i< size;i++)
		syscall(SYSCALL_SEND_TO_GPU,dstX,dstY,srcX,srcY,a_,size);
	    return 1;
    }
    syscall_return_t readGpuMessage(int64_t srcX,int64_t srcY,int64_t dstX,int64_t dstY,int64_t *a, int64_t size)
    {
        for(int i = 0; i< size;i++){
            a[i]=syscall(SYSCALL_READ_FROM_GPU,dstX,dstY,srcX,srcY,a[i],i);
        }
        //return a;
    }
}
