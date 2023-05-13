#!/usr/bin/env bash

set -eu

help() {
cat << EOF
Description:
  This programm is using for system monitoring purposes

Usage: mon.sh [OPTIONS]

OPTIONS:
  -p,   --proc                          Info about /proc/...
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

#----------------------------------------------
# Message helper
gray="\033[2;37m"
blue="\033[0;36m"
red="\033[0;31m"
green="\033[0;92m"
reset="\033[0m"

# Displaying info message
info() {
  if [ -n "$*" ]; then
    echo -e "${blue}❯ $*${reset}";
  fi
}

# Displaying success message
success() {
  if [ -n "$*" ]; then
    echo -e "${green}✔ $*${reset}";
  fi
}

# Displaying failed message and stopping the pipeline
fail() {
  if [ -n "$*" ]; then
    echo -e "${red}✖ $*${reset}"; echo ""; return 1;
  fi
}
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
#----------------------------------------------
# Функция вывода параметров процессора !
cpu_f () {
opt=$1 # Переменная дополнительной опции после cpu

}
#---------------------------------------------
if [ -z $1 ] || [ $1 = '--help' ] || [ $1 = '-h' ]
then
	{
	help;
	}
else
	{

  PARAMS=""

# Проверка наличия опции вывода в файл -o
output_option=false
output_file=""

#if [[ "$@" == *"-o"* ]]; then
#  output_option=true
#  output_file_index=$(echo "$@" | grep -n -e '-o' | cut -d':' -f1)
#  output_file="${@:output_file_index+1:1}"
#  echo $output_file_index
#  echo $output_file
#  if [[ "$output_file" == -* ]]; then
#    echo "Error: Missing output file parameter for -o option" >&2
#    exit 1
#  fi
#fi

for (( i=1; i<=$#; i++ )); do
  if [[ "${!i}" == "-o" ]] && (( i+1 <= $# )); then
    output_option=true
    eval "output_file=\${$((i+1))}"
    break
  fi
done

  while (( "$#" )); do
    case "$1" in
      -p|--proc)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if test -e "/proc/$2"; then
            if [ "$output_option" = true ]; then
              if [ -n "$output_file" ]; then
                 echo "/proc/$2 OUTPUT:"
                 info "$(cat /proc/$2)" >> "$output_file"
                 success "Результат сохранен в файл: $output_file"
              else
                echo "Error: Missing output file parameter for -o option" >&2
                exit 1
              fi
            else
              echo "/proc/$2 OUTPUT:"
              info "$(cat /proc/$2)"
            fi

          else
            fail "Error: Parameter not found in /proc/"
          fi
          shift 2
        else
            fail "Error: Missing /proc/ parameter" >&2
            exit 1
        fi
        ;;

      -m|--memory)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          memory_f $2
          shift 2
        else
          echo "Error: Missing memory parameter" >&2
          exit 1
        fi
        ;;

      -c|--cpu)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          cpu_f $2
          shift 2
        else
          echo "Error: Missing cpu parameter" >&2
          exit 1
        fi
        ;;

       -d | --disks)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          disks_f $2
          shift 2
        else
          echo "Error: Missing disks parameter" >&2
          exit 1
        fi
        ;;

      -n | --network)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          network_f $2
          shift 2
        else
          echo "Error: Missing network parameter" >&2
          exit 1
        fi
        ;;

      -la | --loadaverage)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          loadaverage_f $2
          shift 2
        else
          echo "Error: Missing loadaverage parameter" >&2
          exit 1
        fi
        ;;

      -k | --kill)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          loadaverage_f $2
          shift 2
        else
          echo "Error: Missing kill process parameter" >&2
          exit 1
        fi
        ;;

      -*|--*=)
        shift 1
        ;;

      *)
        PARAMS="$PARAMS $1"
        shift
        ;;
    esac
  done

  eval set -- "$PARAMS"
  }
fi
success "Done!"