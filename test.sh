#!/bin/bash
for (( i=0; i<=15; i++ ))
do ./gpu_hashtable 100 2 0 >> output.txt
done;