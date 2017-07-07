#include <stdio.h>
#include <iostream>
#include <math.h>

// Kernel function to add the elements of two arrays
__global__
void add(int n, float *x, float *y)
{

	int index = threadIdx.x;
	int stride = blockDim.x;
	for (int i = index; i < n; i += stride)
		y[i] = x[i] + y[i];
}


typedef struct {
	float x, y, z;
} Vec3;

typedef struct {
	Vec3 velocity, location;
	float mass;
} Body;

__device__ float dist2(Vec3 a, Vec3 b) {
	return pow(a.x - b.x, 2) + pow(a.y - b.y, 2) + pow(a.z - b.z, 2);
}

//__device__ Vec3 norm(Vec3 )
__global__
void calculate_forces(int n, Body* bodies)
{
	// everyone should have access to a global body list
	// everyone updates their own body
	// __syncthreads and go to another tick? should i pass in tic levels?

	int idx = blockIdx.x * blockDim.x + threadIdx.x;

	float g_const = 10;

	Body* dis_body = &bodies[idx];

	Vec3 force;
	force.x = 0;
	force.y = 0;
	force.z = 0;

	dis_body->mass = 5;

	printf("%f\n", dis_body->mass);
	for(int i = 0; i < n; i++) {

		if(i == idx) {
			continue;
		}

		Body b = bodies[i];

		dis_body->velocity.x += g_const * b.mass * dis_body->mass / dist2(b.location, dis_body->location);
	}

}

int main(void)
{ 
	//int N = 1<<20;
	int N = 10;

	Body* bodies;
	// Allocate Unified Memory – accessible from CPU or GPU
	cudaMallocManaged(&bodies, N * sizeof(Body));
	//cudaMallocManaged(&y, N*sizeof(Body));

	// initialize x and y arrays on the host
	/*
	for (int i = 0; i < N; i++) {
		x[i] = 1.0f;
		y[i] = 2.0f;
	}
	*/
	for(int i = 0; i < N; i++) {
		bodies[i].velocity.x = 0;
		bodies[i].velocity.y = 0;
		bodies[i].velocity.z = 0;

		bodies[i].location.x = 0;
		bodies[i].location.y = 0;
		bodies[i].location.z = 0;

		bodies[i].mass = 0;
	}

	// Run kernel on 1M elements on the GPU
	//add<<<1, 256>>>(N, x, y);
	calculate_forces<<<1, 256>>>(N, bodies);

	// Wait for GPU to finish before accessing on host
	cudaDeviceSynchronize();

	// Check for errors (all values should be 3.0f)
	/*
	float maxError = 0.0f;
	for (int i = 0; i < N; i++)
		maxError = fmax(maxError, fabs(y[i]-3.0f));

	std::cout << "Max error: " << maxError << std::endl;
	*/

	for(int i = 0; i < N; i++) {
		std::cout << "x velocity: " << bodies[i].velocity.x << std::endl;
	}
	std::cout << "donezo" << std::endl;

	// Free memory
	cudaFree(bodies);
	/*
	cudaFree(x);
	cudaFree(y);
	*/

	return 0;
}
