#!/bin/bash
# Read a string with spaces using for loop
# Change allocs.txt to a file of your liking

for value in  Alloc_table_autostats Alloc_thread_stacks Malloc_active_memory Buffer_manager_memory Total_io_pool_memory Alloc_large_variable Alloc_replication_large Alloc_durability_large Alloc_hash_buckets Alloc_mmap_memory Alloc_compiled_unit_sections Alloc_object_code_images Alloc_unit_ifn_thunks Alloc_unit_images Total_server_memory
do
    find . -name allocs.txt | xargs rg $value | sed "s/Value/$value/g"

done

:'Example output

sbroomhead@singlestore ~/D/dell> bash allocs.sh
3850294196291 2022-09-15 11:34:11.527  ERROR: Alloc_table_autostats :  7329.176 MB
3850294195599 2022-09-15 11:34:11.526  ERROR: Alloc_thread_stacks :  682.000 MB
3850294195650 2022-09-15 11:34:11.526  ERROR: Malloc_active_memory :  6783.178 (-7.021) MB
3850294195864 2022-09-15 11:34:11.526  ERROR: Buffer_manager_memory :  78447.8 (+676.5) MB
3850294195541 2022-09-15 11:34:11.526  ERROR: Total_io_pool_memory :  41.5 MB
3850294195935 2022-09-15 11:34:11.526  ERROR: Alloc_large_variable :  276.624 MB
3850294195997 2022-09-15 11:34:11.526  ERROR: Alloc_hash_buckets :  171.682 MB
3850294196140 2022-09-15 11:34:11.526  ERROR: Alloc_mmap_memory :  104.000 (-0.750) MB
3850294196049 2022-09-15 11:34:11.526  ERROR: Alloc_compiled_unit_sections :  872.918 (-0.023) MB
3850294196036 2022-09-15 11:34:11.526  ERROR: Alloc_unit_ifn_thunks :  112.442 MB
3850294196023 2022-09-15 11:34:11.526  ERROR: Alloc_unit_images :  2832.835 (-0.001) MB
3850294195522 2022-09-15 11:34:11.526  ERROR: Total_server_memory :  97824.1 (+669.1) MB
'
