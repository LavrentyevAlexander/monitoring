#! /bin/bash
#---------------------------------------------
# Блок функций
#---------------------------------------------
# Функция проверки наличия файла
#check_file () {
#	comm=$1
#	opt=$#2
#	if [ -f /$comm/$opt ]
#        then true
#        else echo "Файл данных /$comm/$opt отсутствует"
#        fi
#}
#----------------------------------------------
# Функция ввода неверных данных
out_check_opt () {
	echo "Введены неверные параметры, воспользуйтесь разделом справки"
        echo "./server_monitor.sh --help"
	echo "./server_monitor.sh -h"
	echo "./server_monitor.sh"
}
#---------------------------------------------- 
# Функция вывода параметров директории /proc/
proc_f () {
	opt=$1  # Переменная опции
	if [ -z $opt ]
	then
		{
		ls -la /proc/
		}
	else 
		{	
		case $opt in                                                                                                              
		cpuinfo) {
				 	if [ -f /proc/cpuinfo ]
				 	then cat /proc/cpuinfo
				 	else echo "Файл данных /proc/cpuinfo отсутствует"
				 	fi
		 };;
	
		 version) {
					if [ -f /proc/version ]
					then cat /proc/version
					else echo "Файл данных /proc/version отсутствует"
					fi
		};;

		mounts) {
		                        if [ -f /proc/mounts ]
		                        then cat /proc/mounts
		                        else echo "Файл данных /proc/mounts отсутствует"
		                        fi
                };;
		
		cgroups) {
					if [ -f /proc/cgroups ]
		                        then cat /proc/cgroups
					else echo "Файл данных /proc/cgroups отсутствует"
					fi
		};;
		
		filesystems) {
					if [ -f /proc/filesystems ]
       					then cat /proc/filesystems
					else echo "Файл данных /proc/filesystems отсутствует"
					fi
		};;

		meminfo) {
					if [ -f /proc/meminfo ]
                                        then cat /proc/meminfo
					else echo "Файл данных /proc/meminfo отсутствует"
					fi
		};;
		
		stat) {
					if [ -f /proc/stat ]
					then cat /proc/stat
					else echo "Файл данных /proc/stat отсутствует"
					fi	       
		};;

		uptime) { 
					if [ -f /proc/uptime ]
					then cat /proc/uptime
					else echo "Файл данных /proc/uptime отсутствует"
					fi
		};;
		
		version_signature) {
					if [ -f /proc/version_signature ]
					then cat /proc/version_signature
					else echo "Файл данных /proc/version_signature отсутствует"
					fi
		};;

		*) out_check_opt;;
		esac  
		}	
	fi
}
#---------------------------------------------
# Функция вывода параметров процессора

#---------------------------------------------
# Функция вывода параметров директории memory
memory_f () {
	opt=$1  # Переменная дополнительной опции после memory
        if [ -z $opt ]
        then
	   {
	    free
	   }
	else
	   {
	   case $opt in
		    total) {
			   free | awk -F " " '{ if ($1 == "Mem:") print "Всего доступно физической памяти на сервере: "$2 " КБ" }' 
		   	   };;
		     used) {
			   free | awk -F " " '{ if ($1 == "Mem:") print "Использовано памяти: "$3 " КБ"}'
		   	   };;
		     free) {
			   free | awk -F " " '{ if ($1 == "Mem:") print "Свободно памяти: "$4 " КБ"}'
		   	   };;		  
		   shared) {
			   free | awk -F " " '{ if ($1 == "Mem:") print "Использовано памяти файловой системой: = "$5 " КБ" }'
		   	   };;
	   	available) {
			   free | awk -F " " '{ if ($1 == "Mem:") print "Памяти доступно к использованию: "$7 " КБ"}'
			   };;
	                *) out_check_opt;;
	   esac
    	   }
	fi
}
#---------------------------------------------
# Функция выбора первой опции 
select_opt () {
	opt_1=$1 # Опция 1
	opt_2=$2 # Опция 2
	case $1 in
		-p | --proc) proc_f $2;; 
		-c | --cpu) cpu_f $2;;
		-m | --memory) memory_f $2;;
                -d | --disks) disks_f $2;;
                -n | --network) network_f $2;;
               -la | --loadaverage) loadaverage_f $2;;
	        -k | --kill) kill_f $2;;
                *) out_check_opt;;
	esac
}
#---------------------------------------------
# Основной цикл проверки параметров
if [ -z $1 ] || [ $1 = '--help' ] || [ $1 = '-h' ]
then
	{
	cat help.txt
	}
else
	{
#	 echo '$1= '$1
#	 echo '$2= '$2
#	 echo '$3= '$3
#	 echo '$4= '$4
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
