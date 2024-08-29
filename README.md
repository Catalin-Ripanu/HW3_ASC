# HW3_ASC

### Organization
The assignment consisted of designing a **Hash Table** data structure using the graphics card (GPU) so that data manipulation is as simple and fast as possible. The **Linear probing** variant was chosen for organizing the data structure as it is the most trivial and intuitive of those presented in the problem statement. Well, access to hashtable elements in case of a collision is done quickly because the next indices tested in the methods of the **GpuHashTable** class, after calculating the key hash, are adjacent, which gives spatial locality to the implementation. This locality improves the *hit* rate in GPU caches, which leads to a *shorter* data access time in general.

### Implementation
The *GpuHashTable* class retains an important field, namely _hashTable_, which represents the table that will have *Entry* objects that will store the pairs added to the Hash Table, the maximum number of elements that can be stored (capacity), as well as the actual number of stored elements (size).

**Hash Function**

The function was designed using several functions encountered in various parts. The large number of operations performed by this function increases the uniformity of its results distribution.

**Insert Batch**

Initially, the function will copy from RAM to VRAM the keys and values that need to be added, after which it will launch into execution the kernels that actually do the insertion into the Hash Table, one for each added element. The number of threads on each block is the maximum allowed by the *GPU*, to maximize parallelism. It was observed that maximum speed is obtained when the thread blocks have the maximum possible size, namely 1024. When a position in the Hash Table is already occupied by another key, the next position is tried by circularly traversing the *entries* vector. Given that the loading percentage of the table is subunit, it is guaranteed that a position will always be found to add a new key-value pair. At each step, the atomic Compare-And-Set function is used to try these positions. Moreover, *atomicCAS()* acts as a mutex (subsequent calls will not be able to write to that address when it returns KEY_INVALID or the key at the thread index).

**Get Batch**

Finding the key works similarly to that in *insertBatch()*, except that *atomicCas()* is no longer needed since the table is no longer modified. Therefore, each thread will search for one of the keys with the required values, the hash is calculated the same as above and when the key at the position indicated by the hash is the one sought, its value is written in a shared GPU <-> RAM vector.

**Reshape**

Space is allocated for the new pairs and that space is filled with 0. Also, a thread is started for each position in the old table. If there is no valid key at this position, the thread ends. Otherwise, the value associated with the key will be added to the newly allocated table in the same way as in the case of the kernel called by *insertBatch()*.

**Results**

Following execution, the following output is obtained:

```
------- Test T1 START   ----------

HASH_BATCH_INSERT   count: 500000           speed: 72M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 500000           speed: 59M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 500000           speed: 82M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 500000           speed: 74M/sec          loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 65 M/sec,   AVG_GET: 78 M/sec,      MIN_SPEED_REQ: 0 M/sec  


------- Test  T1 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  15 / 80



------- Test T2 START   ----------

HASH_BATCH_INSERT   count: 1000000          speed: 105M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 77M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 131M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 112M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 91 M/sec,   AVG_GET: 122 M/sec,     MIN_SPEED_REQ: 20 M/sec 


------- Test  T2 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  30 / 80



------- Test T3 START   ----------

HASH_BATCH_INSERT   count: 1000000          speed: 102M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 69M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 58M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 1000000          speed: 49M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 104M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 113M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 114M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 1000000          speed: 98M/sec          loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 70 M/sec,   AVG_GET: 107 M/sec,     MIN_SPEED_REQ: 40 M/sec 


------- Test  T3 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  45 / 80



------- Test T4 START   ----------

HASH_BATCH_INSERT   count: 20000000         speed: 169M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 140M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 98M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 20000000         speed: 78M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 212M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 158M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 136M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 20000000         speed: 127M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 121 M/sec,  AVG_GET: 158 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T4 END    ----------       [ OK RESULT:  15  pts ]

Total so far:  60 / 80



------- Test T5 START   ----------

HASH_BATCH_INSERT   count: 50000000         speed: 178M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 50000000         speed: 134M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 50000000         speed: 204M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 50000000         speed: 148M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 156 M/sec,  AVG_GET: 176 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T5 END    ----------       [ OK RESULT:  10  pts ]

Total so far:  70 / 80



------- Test T6 START   ----------

HASH_BATCH_INSERT   count: 10000000         speed: 168M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 124M/sec         loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 99M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 79M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 67M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 59M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 51M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 40M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 40M/sec          loadfactor: 85%         
HASH_BATCH_INSERT   count: 10000000         speed: 37M/sec          loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 150M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 146M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 196M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 155M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 156M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 147M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 141M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 137M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 147M/sec         loadfactor: 85%         
HASH_BATCH_GET      count: 10000000         speed: 116M/sec         loadfactor: 85%         
----------------------------------------------
AVG_INSERT: 76 M/sec,   AVG_GET: 149 M/sec,     MIN_SPEED_REQ: 50 M/sec 


------- Test  T6 END    ----------       [ OK RESULT:  10  pts ]

Total so far:  80 / 80

Total: 80 / 80
```

I chose to resize the table when the fill factor reaches 90% so that the new fill factor reaches around 85%.

It is observed that as the size of the table increases, the overhead is increasingly smaller (the hashes of the keys are recalculated through the *reshape()* function described above).

By eliminating synchronization, it is observed that, without modifying the table and not needing atomic operations or *reshape()*, the *getBatch()* function runs much faster than insertion.

Approximately 50% of the runtime is spent in system calls, so memory (VRAM) is allocated and removed from the GPU. The rest of the time is spent on actual insertion or extraction. It is expected that most of the time consumed will be in *Memcpy()* or *Memset()* because the data has to travel a path with certain limitations (CPU->Motherboard->RAM->Motherboard->CPU->Motherboard->GPU).

This overhead cannot, however, be avoided, given the allocation of data in RAM done in *test_map.cpp*, because for kernels to have access to data, it is necessary for them to be copied into VRAM (GPU) as well.

### Resources Used

5: https://www.geeksforgeeks.org/implementing-hash-table-open-addressing-linear-probing-cpp/

6: https://www.partow.net/programming/hashfunctions/
