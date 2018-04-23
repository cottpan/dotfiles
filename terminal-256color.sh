for i in `seq 255 -1 0`; do
    echo -en "\e[38;5;${i}m${i}\e[0m "
done
printf "\n"
for i in {255..0} ; do echo -en "\e[38;5;${i}m${i}\e[0m " ; done ; echo
