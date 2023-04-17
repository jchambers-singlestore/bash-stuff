#!/bin/bash

## Created by Spencer Broomhead

echo "filename: "
read filename

if [ ! -f $filename ]; then
    echo "File not found!"
    exit
fi

total_server_memory=$(rg -i total_server_memory $filename | sed 's/^[0-9]* [0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\.[0-9]*  ERROR://' | sed 's/.*|.*|.*|.*|\([^|]*\) | \([^|]*\).*/\1 | \2/g')
echo "$total_server_memory"

mem_keys=("Alloc_thread_stacks" "Malloc_active_memory" "Buffer_manager_memory" "Total_io_pool_memory" "Alloc_replication_large" "Alloc_durability_large" "Alloc_mmap_memory" "Alloc_compiled_unit_sections" "Alloc_object_code_images" "Alloc_unit_ifn_thunks" "Alloc_unit_images")
total=0

for key in "${mem_keys[@]}"
do
  mem=$(grep -i "$key" $filename | sed 's/^[0-9]* [0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\.[0-9]*  ERROR: //' | sed 's/.*|.*|.*|.*|\([^|]*\) | \([^|]*\).*/\1 | \2/g')
  if [ -z "$mem" ]; then
    echo "  ├─ $key (not found)"
  else
    if [ "$key" == "Buffer_manager_memory" ]; then
      echo "  ├─ $mem"
      sub_keys=("Buffer_manager_cached_memory" "Alloc_query_execution" "Alloc_table_memory")
      for sub_key in "${sub_keys[@]}"
      do
        sub_mem=$(grep -i "$sub_key" $filename | rg -v Alloc_query_execution_temp_table | sed 's/^[0-9]* [0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\.[0-9]*  ERROR: //' | sed 's/.*|.*|.*|.*|\([^|]*\) | \([^|]*\).*/\1 | \2/g')
        if [ -z "$sub_mem" ]; then
          echo "   │   ├─ $sub_key (not found)"
        else
          if [ "$sub_key" == "Alloc_table_memory" ]; then
            echo "  │    ├─ $sub_mem"
            sub_sub_keys=("Alloc_skiplist_tower" "Alloc_variable" "Alloc_large_variable" "Alloc_table_primary" "Alloc_deleted_version" "Alloc_internal_key_node" "Alloc_hash_buckets" "Alloc_table_autostats")
            for sub_sub_key in "${sub_sub_keys[@]}"
            do
              sub_sub_mem=$(grep -i "$sub_sub_key" $filename | rg -v 'variable_[abc]' | rg -v rust | sed 's/^[0-9]* [0-9]*-[0-9]*-[0-9]* [0-9]*:[0-9]*:[0-9]*\.[0-9]*  ERROR: //' | sed 's/.*|.*|.*|.*|\([^|]*\) | \([^|]*\).*/\1 | \2/g')
              if [ -z "$sub_sub_mem" ]; then
                echo "  │    │   ├─ $sub_sub_key (not found)"
              else
                if [ "$sub_sub_key" == "Alloc_hash_buckets" ] || [ "$sub_sub_key" == "Alloc_large_variable" ]; then
                  echo "  │       ├─ $sub_sub_mem * NOT included in Buffer_manager_memory"
                else
                  echo "  │       ├─ $sub_sub_mem"
                fi
              fi
            done
          else
            echo "  │    ├─ $sub_mem"
          fi
        fi
      done
    else
      echo "  ├─ $mem"
    fi
  fi
done
