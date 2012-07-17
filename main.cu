#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cutil.h>

/* 
 * In CUDA it is necessary to define block sizes
 * The grid of data that will be worked on is divided into blocks
 */
#define BLOCK_SIZE 4
/**
 * This is the function that will be executed on the stream processors
 * The __global__ directive identifies this function as being
 * an executable kernel on the CUDA device.
 * All kernesl must be declared with a return type void 
 */ 
__global__ void cu_img_process(int *img, int *edges, int height, int width, int threshold, float *filter){
    int i;
	int j;
	int pos;
	
	/* blockIdx.x is a built-in variable in CUDA
           that returns the blockId in the x axis.
	   blockIdx.y is a built-in variable in CUDA
           that returns the blockId in the y axis
       threadIdx.x is another built-in variable in CUDA
           that returns the threadId in the x axis
           of the thread that is being executed by this
           stream processor in this particular block
       threadIdx.y is another built-in variable in CUDA
           that returns the threadId in the y axis
           of the thread that is being executed by this
           stream processor in this particular block
        */
	i=blockIdx.x*BLOCK_SIZE+threadIdx.x;
	j=blockIdx.y*BLOCK_SIZE+threadIdx.y;
	pos = i*height+ j;
		
	float sum = 0.0;        
	for(int g = 0; g < 3; g++){
		for(int h = 0; h < 3; h++){                    
			
			if((i == 0 && g == 0) || (i == height-1 && g == 2) || (j == 0 && h == 0) || (j == width-1 && h == 2))
			   continue;                    
			
			sum += filter[g*3+h] * img[(i-1+g)*height + (j-1+h)];
		}
	}
	sum = round(sum);
	if(sum > threshold)
		edges[pos] = 255;
	else
		edges[pos] = 0;
}

extern "C++" void img_process(int *img, int *edges, int height, int width, int threshold){
	//block_d and thread_d are the GPU counterparts of the arrays that exist on the host memory 
	int *img_d;
	int *edges_d;
	float *filter_d;
	
	float filter[] = {-0.0625,-0.0625,-0.0625,-0.0625,0.5,-0.0625,-0.0625,-0.0625,-0.0625};

	//int nBlocks;
	cudaError_t result;
	
	//allocate memory on device
	// cudaMalloc allocates space in the memory of the GPU
	result = cudaMalloc((void**)&img_d,sizeof(int)*height*width);
	if (result != cudaSuccess) {
		printf("cudaMalloc - img_d - failed\n");
		exit(1);
	}
	result = cudaMalloc((void**)&edges_d,sizeof(int)*height*width);
	if (result != cudaSuccess) {
		printf("cudaMalloc - edges_d - failed\n");
		exit(1);
	}
	result = cudaMalloc((void**)&filter_d,sizeof(int)*3*3);
	if (result != cudaSuccess) {
		printf("cudaMalloc - filter_d - failed\n");
		exit(1);
	}
	
	//copy the array into the variable array_d in the device 
	result = cudaMemcpy(img_d,img ,sizeof(int)*height*width,cudaMemcpyHostToDevice);
	if (result != cudaSuccess) {
		printf("cudaMemcpy failed.");
		exit(1);
	}
	result = cudaMemcpy(filter_d, filter,sizeof(int)*3*3,cudaMemcpyHostToDevice);
	if (result != cudaSuccess) {
		printf("cudaMemcpy failed.");
		exit(1);
	}

	//execution configuration...
	// Indicate the dimension of the block
	dim3 dimblock(BLOCK_SIZE,BLOCK_SIZE);
	// Indicate the dimension of the grid 
	//nBlocks = arraySize/BLOCK_SIZE;
	dim3 dimgrid(height/BLOCK_SIZE, width/BLOCK_SIZE);
	//actual computation: Call the kernel
	cu_img_process<<<dimgrid,dimblock>>>(img_d, edges_d, height, width, threshold, filter_d);
	
	//read results back:
	// Copy the results from the memory in the GPU back to the memory on the host
	result = cudaMemcpy(edges,edges_d,sizeof(int)*height*width,cudaMemcpyDeviceToHost);
	if (result != cudaSuccess) {
		printf("cudaMemcpy - GPU to host - edges_d - failed\n");
		exit(1);
	}

	// Release the memory on the GPU 
	cudaFree(img_d);
	cudaFree(edges_d);
	cudaFree(filter_d);
}