#!/usr/bin/env bash

# This script uses for server monitoring purposes

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
    suboptions:
    - load                              CPU load
    - freq                              CPU Frequency
    - arch                              CPU Architecture
    - temp                              CPU Temperature
    - usage                             CPU Core usage
    - cache                             CPU Cache size
    - inter                             CPU Interrupts
  -m,   --memory                        Info about RAM
    suboptions:
    - total                             Total physical memory on the server
    - used                              Size of used memory
    - free                              Size of free memory
    - shared                            Size of memory used by filesystem
    - available                         Available memory for using
  -d,   --disks                         Info about disk memory
    suboptions:
    - load                              Disk load
    - space                             Disk available space
    - latency                           Disk latency
    - errors                            Disk errors
    - cache                             Disk cache utilization
    - temp                              Disk temperature
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
# Function for output information about memory
memory_f () {
	opt=$1
     case $opt in
        total) {
                free | awk -F " " '{ if ($1 == "Mem:") print "Available physical server memory: "$2 " KB" }'
              };;
        used) {
                free | awk -F " " '{ if ($1 == "Mem:") print "Memory used: "$3 " KB"}'
              };;
        free) {
                free | awk -F " " '{ if ($1 == "Mem:") print "Free memory: "$4 " KB"}'
              };;
        shared) {
                free | awk -F " " '{ if ($1 == "Mem:") print "Memory used by filesystem: = "$5 " KB" }'
              };;
        available) {
                free | awk -F " " '{ if ($1 == "Mem:") print "Available memory: "$7 " KB"}'
              };;
        *) out_check_opt;;
     esac
}
#----------------------------------------------
# Function for output information about CPU
cpu_f () {
opt=$1
     case $opt in
        load) {
                cpu_load=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}')
                echo "CPU Load: ${cpu_load}%"
              };;
        freq) {
                echo "CPU Frequency: $(lscpu | grep "CPU MHz" | awk '{print $3}') MHz"
              };;
        arch) {
                echo "CPU Architecture: $(uname -m)"
              };;
        temp) {
                echo "CPU Temperature: $(sensors | grep "Core 0" | awk '{print $3}')"
              };;
        usage) {
                echo "CPU Core usage: $(top -bn1 | grep "Cpu(s)")"
              };;
        cache) {
                echo "CPU Cache size: $(lscpu | grep "L3 cache" | awk '{print $3, $4}')"
              };;
        inter) {
                echo "CPU Interrupts: $(cat /proc/interrupts | grep -v CPU)"
              };;
        *) out_check_opt;;
     esac
}
#---------------------------------------------
# Function for output information about DISK system
disk_f () {
opt=$1
     case $opt in
        load) {
                echo "Disk Load: $(iostat -d | grep 'sda' | awk '{print $2}')" # sudo apt install sysstat
              };;
        space) {
                echo "Available disk space: $(df -h | grep '/dev/sda1' | awk '{print $4}')"
              };;
        latency) {
                echo "Disk Latency: $(iostat -d | grep 'sda' | awk '{print $10}')" # sudo apt install sysstat
              };;
        errors) {
                echo "Disk Errors: $(smartctl -a /dev/sda | grep 'Errors' | awk '{print $2}')" # sudo apt install smartmontools
              };;
        cache) {
                echo "Disk Cache Utilization: $(cat /proc/meminfo | grep 'Cached:' | awk '{print $2}')"
              };;
        temp) {
                echo "Disk Temperature: $(smartctl -a /dev/sda | grep 'Temperature' | awk '{print $10}')" # sudo apt install smartmontools
              };;
        *) out_check_opt;;
     esac
}
#---------------------------------------------
# Function for output information about Network interfaces - Fill
network_f () {
opt=$1
     case $opt in
        load) {
                echo "Disk Load: $(iostat -d | grep 'sda' | awk '{print $2}')" # sudo apt install sysstat
              };;
        space) {
                echo "Available disk space: $(df -h | grep '/dev/sda1' | awk '{print $4}')"
              };;
        latency) {
                echo "Disk Latency: $(iostat -d | grep 'sda' | awk '{print $10}')" # sudo apt install sysstat
              };;
        errors) {
                echo "Disk Errors: $(smartctl -a /dev/sda | grep 'Errors' | awk '{print $2}')" # sudo apt install smartmontools
              };;
        cache) {
                echo "Disk Cache Utilization: $(cat /proc/meminfo | grep 'Cached:' | awk '{print $2}')"
              };;
        temp) {
                echo "Disk Temperature: $(smartctl -a /dev/sda | grep 'Temperature' | awk '{print $10}')" # sudo apt install smartmontools
              };;
        *) out_check_opt;;
     esac
}
#---------------------------------------------
# Function for output information about System Loadaverage - Fill
loadaverage_f () {
opt=$1
     case $opt in
        load) {
                echo "Disk Load: $(iostat -d | grep 'sda' | awk '{print $2}')" # sudo apt install sysstat
              };;
        space) {
                echo "Available disk space: $(df -h | grep '/dev/sda1' | awk '{print $4}')"
              };;
        latency) {
                echo "Disk Latency: $(iostat -d | grep 'sda' | awk '{print $10}')" # sudo apt install sysstat
              };;
        errors) {
                echo "Disk Errors: $(smartctl -a /dev/sda | grep 'Errors' | awk '{print $2}')" # sudo apt install smartmontools
              };;
        cache) {
                echo "Disk Cache Utilization: $(cat /proc/meminfo | grep 'Cached:' | awk '{print $2}')"
              };;
        temp) {
                echo "Disk Temperature: $(smartctl -a /dev/sda | grep 'Temperature' | awk '{print $10}')" # sudo apt install smartmontools
              };;
        *) out_check_opt;;
     esac
}
#---------------------------------------------
# Function for killing processes - Fill
kill_f () {
opt=$1
     case $opt in
        load) {
                echo "Disk Load: $(iostat -d | grep 'sda' | awk '{print $2}')" # sudo apt install sysstat
              };;
        space) {
                echo "Available disk space: $(df -h | grep '/dev/sda1' | awk '{print $4}')"
              };;
        latency) {
                echo "Disk Latency: $(iostat -d | grep 'sda' | awk '{print $10}')" # sudo apt install sysstat
              };;
        errors) {
                echo "Disk Errors: $(smartctl -a /dev/sda | grep 'Errors' | awk '{print $2}')" # sudo apt install smartmontools
              };;
        cache) {
                echo "Disk Cache Utilization: $(cat /proc/meminfo | grep 'Cached:' | awk '{print $2}')"
              };;
        temp) {
                echo "Disk Temperature: $(smartctl -a /dev/sda | grep 'Temperature' | awk '{print $10}')" # sudo apt install smartmontools
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
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "DISK $2 OUTPUT:" >> "$output_file"
               info "$(disk_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "DISK $2 OUTPUT:"
            info "$(disk_f $2)"
          fi
          shift 2
        else
          echo "DISK system information:"
          info "$(df -h)"
          shift 1
        fi
        ;;

      -n | --network)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "NETWORK $2 OUTPUT:" >> "$output_file"
               info "$(network_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "NETWORK $2 OUTPUT:"
            info "$(network_f $2)"
          fi
          shift 2
        else
          echo "NETWORK system information:"
          info "$(ifconfig)"
          shift 1
        fi
        ;;

      -la | --loadaverage)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "Loadaverage $2 OUTPUT:" >> "$output_file"
               info "$(loadaverage_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "Loadaverage $2 OUTPUT:"
            info "$(loadaverage_f $2)"
          fi
          shift 2
        else
          echo "Loadavarage system information:"
          info "$(df -h)" # Fix
          shift 1
        fi
        ;;

      -k | --kill)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
               echo "OUTPUT:" >> "$output_file"
               info "$(kill_f $2)" >> "$output_file"
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            echo "OUTPUT:"
            info "$(kill_f $2)"
          fi
          shift 2
        else
          echo "Kill function:"
          info "$(kill --help)"
          shift 1
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
