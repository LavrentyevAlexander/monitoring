#!/usr/bin/env bash

set -eu

output_option=false
output_file=""

help() {
cat << EOF
Description:
  This programm is using for system monitoring purposes

Usage: ./mon.sh [OPTIONS]

OPTIONS:
  -p,   --proc                          Info from proc folder
  -c,   --cpu                           Info about CPU
  -m,   --memory                        Info about RAM
    suboptions:
    - total                             Total physical memory on the server
    - used                              Amount of used memory
    - free                              Amount of free memory
    - shared                            Amount of memory used by filesystem
    - available                         Available memory for using
  -d,   --disks                         Info about disk memory
  -n,   --network                       Info about network
  -la,  --loadaverage                   Info about system loadaverage
  -k,   --kill                          Send kill signal to process
  -o,   --output                        Save script results to the disk
  -h,   --help                          Help

  Examples:

  1. For display "cpuinfo" information
      ./mon.sh -p cpuinfo
      or
      ./mon.sh --proc cpuinfo

  2. For display amount of memory space used by filesystem and out to file with name free_mem.txt
      ./mon.sh -m shared -o shared_mem.txt
      or
      ./mon.sh -o shared_mem.txt --memory shared
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
#----------------------------------------------
# Функция вывода параметров процессора
cpu_f () {
opt=$1
     case $opt in
        load) {
                cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
                echo "CPU Load: ${cpu_load}%"
              };;
        model) {
                echo "Model name: $(lscpu | grep "Model:" | awk -F ": " '{print $2}')"
              };;
        arch) {
                echo "Architecture: $(uname -m)"
              };;
        cores) {
                echo "CPU cores: $(lscpu | grep "CPU(s):" | awk '{print $2}')"
              };;
        freq) {
                echo "CPU frequency: $(lscpu | grep "CPU MHz:" | awk '{print $3}') MHz"
              };;
        cache) {
                echo "Cache size: $(lscpu | grep "L3 cache:" | awk '{print $3, $4}')"
              };;
        *) out_check_opt;;
     esac
}
#---------------------------------------------
if [ -z "${1+x}" ] || [ $1 = '--help' ] || [ $1 = '-h' ]
then
	{
	help;
	}
else
	{

  PARAMS=""

for (( i=1; i<=$#; i++ )); do
  if ([[ "${!i}" == "-o" ]] || [[ "${!i}" == "--output" ]]) && (( i+1 <= $# )); then
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
                 echo "/proc/$2 OUTPUT:" >> "$output_file"
                 info "$(cat /proc/$2)" >> "$output_file"
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
            echo "/proc/ OUTPUT:"
            ls -la /proc/
            shift 1
        fi
        ;;

      -m|--memory)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "memory $2 OUTPUT:" >> "$output_file"
               info "$(memory_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "Memory $2 OUTPUT:"
            info "$(memory_f $2)"
          fi
          shift 2
        else
          echo "Memory status:"
          echo "$(free)"
          shift 1
        fi
        ;;

      -c|--cpu)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "CPU $2 OUTPUT:" >> "$output_file"
               info "$(cpu_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "CPU $2 OUTPUT:"
            info "$(cpu_f $2)"
          fi
          shift 2
        else
          echo "CPU information:"
          info "$(lscpu)"
          shift 1
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
          kill_f $2
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

  if [ -n "$output_file" ]; then
     success "Результат сохранен в файл: $output_file"
  fi

  success "Done!"
  }
fi
