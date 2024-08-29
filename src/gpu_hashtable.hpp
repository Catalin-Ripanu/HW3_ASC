#ifndef _HASHCPU_
#define _HASHCPU_

using namespace std;

#define PRODUCT 1645457llu
#define MODULO 2545454544565llu
#define KEY_INVALID 0
#define MIN_LOAD_LIMIT 0.85f
#define MAX_LOAD_LIMIT 0.9f

class Entry
{
public:
	int key;
	int value;
};

class HashTable
{
public:
	Entry *entries;
	int capacity;
	int size;
	HashTable(Entry *, int, int);
	HashTable();
};

class GpuHashTable
{
public:
	HashTable hashTable;
	GpuHashTable(int size);
	void reshape(int sizeReshape);

	bool insertBatch(int *keys, int *values, int numKeys);
	int *getBatch(int *key, int numItems);

	~GpuHashTable();
};

#endif
