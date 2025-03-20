#!/bin/zsh
#Utility to create a csv file in the local directory (as well as an array with VRAM use - indexed against the # of offloaded layers) with VRAM use per offloaded layers. 
# Iterate over numbers 1 to max layers ml, where ml is determined empirically per model and GPU and is preset in qlm.cfg ($gpulayers assoc. array)
ml=34  # For Gemma3-27B_Q5_K_L
#The file containing the ModelName array to be used by qlm for dynamic -ngl N AND the name of the array, contents pasted to the end of qlm.cfg
#Please, see the bottom of qlm.cfg to understand what this script does.
filem='Gemma3_27B'

echo -n "${filem}=(" > $filem 
for i in {1..$ml}; do
    qlm --log-file /dev/shm/log$i -ngl $i --simple-io -- $filem "List the first 30 digits of sqrt(2)." > output.log &
    LLAMA_PID=$!
    if [ -z "$LLAMA_PID" ]; then
        echo "Error: Failed to get PID for qlm process."
        return 1
    fi
    sleep 11  # Increase sleep duration if machine is slow or decrease if needed.
    str=$(nvidia-smi --query-gpu=memory.free,memory.used,memory.reserved,memory.total --format=csv,nounits,noheader)
    memvals=(${(s:, :)str})
    echo "|$i|$memvals[1]|$memvals[2]|ts|" >> results$filem
    echo -n "$memvals[2] " >> $filem
    wait $LLAMA_PID
done
echo -n ')' > $filem 
#Assuming this script remains in the same directory as qlm.cfg
cat $filem >> qlm.cfg

#The next will work until llama-cli changes the standard output format.
for i in {1..$ml}; do
last_line=$(tail -n 1 /dev/shm/log$i)
time=$(echo $last_line | awk '{print $5}')
tokens=$(echo $last_line | awk '{print $8}')
result=$(( 1000 * $tokens / $time ))
sed -i "${i}s/ts/${result}/" results$filem
done
#Convert to csv file:
sed 's/^|//;s/|$//;s/|/,/g' results$filem > results$filem.csv
