#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <ctime>
#include <sstream>
#include <string>
#include "test_map.hpp"
#include "gpu_hashtable.hpp"

/* Functia care returneaza informatiile necesare rularii kernel-ului */

cudaError_t getGPUInformation(int &numBlocks, int &numThreads,
							  int numItems)
{
	cudaDeviceProp deviceProp;
	cudaError_t returnValue;

	returnValue = cudaGetDeviceProperties(&deviceProp, 0);
	DIE(returnValue, "cudaGetDeviceProperties() failed");

	numThreads = deviceProp.maxThreadsPerBlock;
	numBlocks = numItems / numThreads;

	if (numBlocks * numThreads != numItems)
	{
		numBlocks = numBlocks + 1;
	}

	return (cudaError_t)0;
}

/* Metode specifice clasei care modeleaza Hash Table-ul */

HashTable::HashTable(Entry *entries, int capacity, int size)
{
	this->entries = entries;
	this->capacity = capacity;
	this->size = size;
}

HashTable::HashTable()
{
	this->capacity = 0;
	this->size = 0;
	this->entries = nullptr;
}

/* Funtia care modeleaza functia de dispersie aproape injectiva */

static __device__ int triple32inc(long long x, int capacity)
{
	long long var = x * PRODUCT;
	var = var % MODULO;
	return var % capacity;
}

/* Functia in care kernel-ul recalculeaza cheia din bucket-urile vechi si
   o plaseaza impreuna cu valoarea sa in noul set de bucket-uri */

__global__ void reshape_entry(Entry *oldEntries, int oldCapacity,
							  Entry *newEntries, int newCapacity)
{
	unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= oldCapacity)
		return;
	if (oldEntries[idx].key == KEY_INVALID)
		return;

	int key_to_add = oldEntries[idx].key;
	int hash = triple32inc(key_to_add, newCapacity);

	while (1)
	{
		int key_before = atomicCAS(&newEntries[hash].key,
								   KEY_INVALID, key_to_add);
		if (key_before == KEY_INVALID)
		{
			atomicExch(&newEntries[hash].value, oldEntries[idx].value);
			return;
		}
		hash = (hash + 1) % newCapacity;
	}
}

/* Functia in care kernel-ul cauta sa puna in vectorul
   'values' valoarea corespunzatoare cheii */

__global__ void get_entry(int *keys, int *values, int numKeys,
						  HashTable hashTable)
{
	unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= numKeys)
		return;
	int key_to_find = keys[idx];
	int hash = triple32inc(key_to_find, hashTable.capacity);

	while (1)
	{
		if (hashTable.entries[hash].key == key_to_find)
		{
			atomicExch(&values[idx], hashTable.entries[hash].value);
			return;
		}
		hash = (hash + 1) % hashTable.capacity;
	}
}

/* Functia in care kernel-ul se ocupa cu inserarea unui
   singur element in Hash Table folosind Linear Probing */

__global__ void insert_entry(int *keys, int *values, int numKeys,
							 HashTable hashTable)
{
	unsigned int idx = blockIdx.x * blockDim.x + threadIdx.x;
	if (idx >= numKeys)
		return;
	if (keys[idx] <= 0 || values[idx] <= 0)
		return;

	int addKeys = keys[idx];
	int hash = triple32inc(addKeys, hashTable.capacity);

	while (1)
	{
		int oldKey = atomicCAS(&hashTable.entries[hash].key,
							   KEY_INVALID, addKeys);

		/* Valoarea se modifica atunci cand 'oldKey' este 'KEY_INVALID'
		   sau cand este identica cu noua cheie */

		if (oldKey == KEY_INVALID || oldKey == addKeys)
		{
			atomicExch(&hashTable.entries[hash].value, values[idx]);
			return;
		}
		hash = (hash + 1) % hashTable.capacity;
	}
}

/* Metodele de prelucrare pentru un Hash Table pe GPU */

GpuHashTable::GpuHashTable(int size)
{
	cudaError_t error;
	hashTable.entries = nullptr;
	hashTable.size = 0;
	hashTable.capacity = size;

	error = glbGpuAllocator->_cudaMalloc((void **)&hashTable.entries, size * sizeof(Entry));
	DIE(error, "cudaMalloc() failed");
	error = cudaMemset(hashTable.entries, 0, size * sizeof(Entry));
	DIE(error, "cudaMemset() failed");
}

/* Stergere Hash Table */

GpuHashTable::~GpuHashTable()
{
	DIE(glbGpuAllocator->_cudaFree(hashTable.entries), "cudaFree() failed");
}

/* Redimensionare Hash Table */

void GpuHashTable::reshape(int numBucketsReshape)
{
	Entry *entries;
	cudaError_t error;
	int numBlocks = 0, numThreads = 0;

	error = glbGpuAllocator->_cudaMalloc((void **)&entries, numBucketsReshape * sizeof(Entry));
	DIE(error, cudaGetErrorString(error));
	error = cudaMemset(entries, 0, numBucketsReshape * sizeof(Entry));
	DIE(error, cudaGetErrorString(error));

	getGPUInformation(numBlocks, numThreads, hashTable.capacity);
	reshape_entry<<<numBlocks, numThreads>>>(hashTable.entries,
											 hashTable.capacity, entries, numBucketsReshape);

	error = cudaDeviceSynchronize();
	DIE(error, cudaGetErrorString(error));

	error = glbGpuAllocator->_cudaFree(hashTable.entries);
	DIE(error, cudaGetErrorString(error));

	hashTable.entries = entries;
	hashTable.capacity = numBucketsReshape;
}

/* Inserare Hash Table */

bool GpuHashTable::insertBatch(int *keys, int *values, int numKeys)
{
	/* Se modifica dimensiunea cand se depaseste pragul maxim */

	if (static_cast<float>(hashTable.size + numKeys) /
			static_cast<float>(hashTable.capacity) >
		MAX_LOAD_LIMIT)
	{

		reshape(static_cast<float>(hashTable.size +
								   numKeys) /
				MIN_LOAD_LIMIT);
	}

	int *gpuKeys, *gpuValues;
	cudaError_t error;
	int numBlocks, numThreads;

	error = glbGpuAllocator->_cudaMalloc((void **)&gpuKeys, numKeys * sizeof(int));
	DIE(error, cudaGetErrorString(error));
	error = glbGpuAllocator->_cudaMalloc((void **)&gpuValues, numKeys * sizeof(int));
	DIE(error, cudaGetErrorString(error));

	error = cudaMemcpy(gpuKeys, keys, numKeys * sizeof(int),
					   cudaMemcpyHostToDevice);
	DIE(error, cudaGetErrorString(error));
	error = cudaMemcpy(gpuValues, values, numKeys * sizeof(int),
					   cudaMemcpyHostToDevice);
	DIE(error, cudaGetErrorString(error));

	getGPUInformation(numBlocks, numThreads, numKeys);
	insert_entry<<<numBlocks, numThreads>>>(gpuKeys, gpuValues,
											numKeys, hashTable);

	error = cudaDeviceSynchronize();
	DIE(error, cudaGetErrorString(error));
	hashTable.size += numKeys;

	error = glbGpuAllocator->_cudaFree(gpuKeys);
	DIE(error, cudaGetErrorString(error));
	error = glbGpuAllocator->_cudaFree(gpuValues);
	DIE(error, cudaGetErrorString(error));

	return true;
}

/* Obtinerea unor elemente din Hash Table */

int *GpuHashTable::getBatch(int *keys, int numKeys)
{
	int *gpuKeys, *gpuValues, *result;
	cudaError_t error;
	int numBlocks, numThreads;

	result = (int *)malloc(numKeys * sizeof(int));
	DIE(!result, "Malloc");
	error = glbGpuAllocator->_cudaMalloc((void **)&gpuKeys, numKeys * sizeof(int));
	DIE(error, cudaGetErrorString(error));
	error = glbGpuAllocator->_cudaMalloc((void **)&gpuValues, numKeys * sizeof(int));
	DIE(error, cudaGetErrorString(error));

	error = cudaMemset(gpuValues, -1, numKeys * sizeof(int));
	DIE(error, cudaGetErrorString(error));
	error = cudaMemcpy(gpuKeys, keys, numKeys * sizeof(int),
					   cudaMemcpyHostToDevice);
	DIE(error, cudaGetErrorString(error));

	getGPUInformation(numBlocks, numThreads, hashTable.capacity);
	get_entry<<<numBlocks, numThreads>>>(gpuKeys, gpuValues,
										 numKeys, hashTable);

	error = cudaDeviceSynchronize();
	DIE(error, cudaGetErrorString(error));

	error = cudaMemcpy((void **)result, gpuValues, numKeys * sizeof(int),
					   cudaMemcpyDeviceToHost);
	DIE(error, cudaGetErrorString(error));

	error = glbGpuAllocator->_cudaFree(gpuKeys);
	DIE(error, cudaGetErrorString(error));
	error = glbGpuAllocator->_cudaFree(gpuValues);
	DIE(error, cudaGetErrorString(error));

	return result;
}
