#!/usr/bin/env bash

set -eu

help() {
cat << EOF
Description:
  This programm is using for system monitoring purposes

Usage: mon.sh [OPTIONS]

OPTIONS:
  -p,   --proc                          Info about /proc
  -c,   --cpu                           Info about processor
  -m,   --memory                        Info about memory
  -d,   --disks                         Info about disk memory
  -n,   --network                       Info about network
  -la,  --loadaverage                   Info about system loadaverage
  -k,   --kill                          Send kill signal to process
  -o,   --output                        Save script results to the disk
  -h,   --help                          Help
EOF
}

#---------------------------------------------
# Основной цикл проверки параметров
if [ -z $1 ] || [ $1 = '--help' ] || [ $1 = '-h' ]
then
	{
	help;
	}
else
	{
				if ! [ -z $3 ] && ([ $3 == '-o' ] || [ $3 == '--output' ])
				then
					{
					if [ -n $4 ] && [ -d $4 ]
					then {
						if [ -z $4 ]
						then {
						echo "Выполнено сохранение в текущей директории в файл: "$4${1/-/out}"$2".txt
						select_opt $1 $2 > $4${1/-/out}"$2"_out.txt
						}
					else {
						echo "Выполнено сохранение в файл: "$4${1/-/out_}"$2".txt
						select_opt $1 $2 > $4${1/-/out}"$2".txt
						}
						fi
					     }
					else echo "Проверьте путь сохранения"
					fi
				     	}
				else select_opt $1 $2
				fi
	}
fi
