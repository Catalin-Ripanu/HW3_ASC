# HW3_ASC

## Organization

- Designed a **Hash Table** data structure using GPU for fast data manipulation.
- Chose **Linear probing** for collision resolution due to its simplicity and intuitive nature.
- Leverages spatial locality for quick access to elements during collisions, improving GPU cache hit rates and reducing data access time.

## Implementation

### Key Components

1. **GpuHashTable Class**:
   - Main field: `_hashTable` (stores Entry objects with key-value pairs)
   - Tracks capacity (maximum number of elements) and current size (actual number of stored elements)

2. **Hash Function**:
   - Designed using multiple sub-functions for uniform distribution of results
   - Large number of operations increases uniformity of distribution

3. **Insert Batch**:
   - Copies keys and values from RAM to VRAM
   - Launches kernels for each element insertion
   - Uses maximum allowed threads per block (1024) for optimal parallelism
   - Implements circular traversal for collision resolution
   - Utilizes atomic Compare-And-Set function (`atomicCAS()`) for thread safety
   - Guaranteed to find a position due to subunit loading percentage

4. **Get Batch**:
   - Similar to insertBatch, but without `atomicCAS()`
   - Each thread searches for one key
   - Calculates hash the same way as in insertBatch
   - Writes found values to a shared GPU <-> RAM vector

5. **Reshape**:
   - Allocates space for new pairs and fills with 0
   - Starts a thread for each position in the old table
   - Rehashes and inserts valid entries into the new table
   - Uses same insertion method as insertBatch kernel

## Results

- Provided detailed performance metrics for various test cases (T1 to T6)
- Demonstrated increasing efficiency with larger table sizes
- getBatch() shows higher performance due to lack of synchronization needs

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

## Performance Analysis

- Resize threshold: 90% fill factor, aiming for 85% after resize
- System calls (memory allocation/deallocation) consume about 50% of runtime
- Data transfer between CPU, RAM, and GPU contributes significantly to overhead
- getBatch() runs faster than insertion due to lack of table modification and atomic operations
- Overhead cannot be avoided due to initial data allocation in RAM (test_map.cpp)

## Detailed Test Results

- Included comprehensive test results showing insert and get speeds for different data sizes
- Tests T1 through T6 demonstrate performance across various scenarios
- All tests passed, achieving maximum points (80/80)

## Resources

- Referenced GeeksForGeeks for open addressing and linear probing implementation
- Used hash function ideas from partow.net

This summary retains all the key information from the original document, including implementation details, performance analysis, and test results.

### Resources Used

5: https://www.geeksforgeeks.org/implementing-hash-table-open-addressing-linear-probing-cpp/

6: https://www.partow.net/programming/hashfunctions/
