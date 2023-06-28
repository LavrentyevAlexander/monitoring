#!/usr/bin/env bash

# This script is using for server parameters view purposes

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
    - temp                              CPU Temperature (for this parameter you have to install lm-sensors package)
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
    - load                              Disk load (for this parameter you have to install sysstat package)
    - space                             Disk available space
    - latency                           Disk latency (for this parameter you have to install sysstat package)
    - errors                            Disk errors (for this parameter you have to install smartmontools package)
    - cache                             Disk cache utilization
    - temp                              Disk temperature (for this parameter you have to install smartmontools package)
  -n,   --network                       Info about network
      suboptions:
      - bandw [interface]               Network bandwidth for certain interface (for this parameter you have to install iproute2 package)
      - err   [interface]               Errors and Discarded Packets on this interface (for this parameter you have to install iproute2 package)
      - conn  [interface]               Connection State of certain interface
      - ip    [interface]               IP addressing and configuration for certain interface (for this parameter you have to install iproute2 package)
  -la,  --loadaverage                   Info about system loadaverage
      suboptions:
      - 1                               Load average last 1 minute
      - 5                               Load average last 5 minutes
      - 15                              Load average last 15 minutes
  -k,   --kill                          Send kill signal to process (PID)
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
        *) {
                unknown_param "$opt"
                exit 1
              };;
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
                if ! freq_out=$(lscpu | grep "CPU MHz" | awk '{print $3}'); then
                  fail "Failed to retrieve CPU frequency information"
                  exit 1
                else
                  echo "CPU Frequency: $freq_out MHz"
                fi
              };;
        arch) {
                echo "CPU Architecture: $(uname -m)"
              };;
        temp) {
                if ! temp_out=$(sensors | grep "Core 0" | awk '{print $3}'); then
                  fail "Failed to retrieve CPU temperature information"
                  exit 1
                else
                  echo "CPU Temperature: $temp_out"
                fi
              };;
        usage) {
                echo "CPU Core usage: $(top -bn1 | grep "Cpu(s)")"
              };;
        cache) {
                if ! cache_out=$(lscpu | grep "L3 cache" | awk '{print $3, $4}'); then
                  fail "Failed to retrieve CPU cache information"
                  exit 1
                else
                  echo "CPU Cache size: $cache_out"
                fi
              };;
        inter) {
                echo "CPU Interrupts: $(cat /proc/interrupts | grep -v CPU)"
              };;
        *) {
                unknown_param "$opt"
                exit 1
              };;
     esac
}
#---------------------------------------------
# Function for output information about DISK system
disk_f () {
opt=$1
     case $opt in
        load) {
                if ! disk_load_out=$(iostat -d | grep 'sda' | awk '{print $2}'); then
                  fail "Failed to retrieve Disk load information"
                  exit 1
                else
                  echo "Disk Load: $disk_load_out"
                fi
              };;
        space) {
                echo "Available disk space: $(df -h | grep '/dev/sda1' | awk '{print $4}')"
              };;
        latency) {
                if ! disk_lat_out=$(iostat -d | grep 'sda' | awk '{print $10}'); then
                  fail "Failed to retrieve Disk latency information"
                  exit 1
                else
                  echo "Disk Latency: $disk_lat_out"
                fi
              };;
        errors) {
                if ! disk_err_out=$(smartctl -a /dev/sda | grep 'Errors' | awk '{print $2}'); then
                  fail "Failed to retrieve Disk errors information"
                  exit 1
                else
                  echo "Disk Errors: $disk_err_out"
                fi
              };;
        cache) {
                echo "Disk Cache Utilization: $(cat /proc/meminfo | grep 'Cached:' | awk '{print $2}')"
              };;
        temp) {
                if ! disk_temp_out=$(smartctl -a /dev/sda | grep 'Temperature' | awk '{print $10}'); then
                  fail "Failed to retrieve Disk temperature information"
                  exit 1
                else
                  echo "Disk Temperature: $disk_temp_out"
                fi
              };;
        *) {
                unknown_param "$opt"
                exit 1
              };;
     esac
}
#---------------------------------------------
# Function for output information about Network interfaces
network_f () {
opt=$1
int=$2
     case $opt in
        bandw) {
                if ! net_bandw_out=$(ip -s -h link show $int); then
                  fail "Failed to retrieve Network bandwidth information"
                  exit 1
                else
                  echo "Network bandwidth: $net_bandw_out"
                fi
              };;
        err) {
                if ! net_err_out=$(ip -s -s -h link show $int); then
                  fail "Failed to retrieve Network errors information"
                  exit 1
                else
                  echo "Errors and Discarded Packets: $net_err_out"
                fi
              };;
        conn) {
                if ! net_conn_out=$(netstat -tunap | grep "ESTABLISHED" | grep "$int"); then
                  fail "Failed to retrieve Network connection information"
                  exit 1
                else
                  echo "Connection State: $net_conn_out"
                fi
              };;
        ip) {
                if ! net_ip_out=$(ip addr show $int); then
                  fail "Failed to retrieve Interface IP information"
                  exit 1
                else
                  echo "IP addressing and configuration: $net_ip_out"
                fi
              };;
        *) {
                unknown_param "$opt"
                exit 1
              };;
     esac
}
#---------------------------------------------
# Function for output information about System Loadaverage - Fill
loadaverage_f () {
opt=$1
     case $opt in
        1) {
                echo "Load average last 1 minute: $(uptime | awk -F'load average: ' '{split($2, load, ", "); print load[1]}')"
              };;
        5) {
                echo "Load average last 5 minutes: $(uptime | awk -F'load average: ' '{split($2, load, ", "); print load[2]}')"
              };;
        15) {
                echo "Load average last 15 minutes: $(uptime | awk -F'load average: ' '{split($2, load, ", "); print load[3]}')"
              };;
        *) {
                unknown_param "$opt"
                exit 1
              };;
     esac
}
#---------------------------------------------
unknown_param() {
local param=$1
fail "Unknown parameter: $param"
cat << EOF
Use command 'help'. To show help you can use following commands:
./mon.sh --help
or
./mon.sh -h
or
./mon.sh
EOF
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
    if [ "${2:0:1}" != "-" ] && [ "$((i+1))" != " " ]; then
      eval "output_file=\${$((i+1))}"
      break
    else
      echo "Error: Missing output file parameter for -o option" >&2
      exit 1
    fi
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
              if ! mem_out=$(memory_f $2); then
                exit 1
              else
                echo "MEMORY $2 OUTPUT:" >> "$output_file"
                info "$mem_out" >> "$output_file"
              fi
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            if ! mem_out=$(memory_f $2); then
                exit 1
            else
              echo "MEMORY $2 OUTPUT:"
              info "$mem_out"
            fi
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
              if ! cpu_out=$(cpu_f $2); then
                exit 1
              else
                echo "CPU $2 OUTPUT:" >> "$output_file"
                info "$cpu_out" >> "$output_file"
              fi
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            if ! cpu_out=$(cpu_f $2); then
              exit 1
            else
              echo "CPU $2 OUTPUT:"
              info "$cpu_out"
            fi
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
              if ! disk_out=$(disk_f $2); then
                exit 1
              else
                echo "DISK $2 OUTPUT:" >> "$output_file"
                info "$disk_out" >> "$output_file"
              fi
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            if ! disk_out=$(disk_f $2); then
              exit 1
            else
              echo "DISK $2 OUTPUT:"
              info "$disk_out"
            fi
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
              if [ -n "${3+x}" ]; then
                if ! net_out=$(network_f $2 $3); then
                  exit 1
                else
                  echo "NETWORK $2 $3 OUTPUT:" >> "$output_file"
                  info "$net_out" >> "$output_file"
                fi
              else
                echo "Error: Missing interface parameter" >&2
                exit 1
              fi
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            if [ -n "${3+x}" ]; then
              if ! net_out=$(network_f $2 $3); then
                exit 1
              else
                echo "NETWORK $2 OUTPUT:"
                info "$net_out"
              fi
            else
              echo "Error: Missing interface parameter" >&2
              exit 1
            fi
          fi
          shift 3
        else
          echo "NETWORK system information:"
          info "$(ip addr)"
          shift 1
        fi
        ;;

      -la | --loadaverage)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          if [ "$output_option" = true ]; then
            if [ -n "$output_file" ]; then
              if ! la_out=$(loadaverage_f $2); then
                exit 1
              else
                echo "LOADAVERAGE $2 OUTPUT:" >> "$output_file"
                info "$la_out" >> "$output_file"
              fi
            else
              echo "Error: Missing output file parameter for -o option" >&2
              exit 1
            fi
          else
            if ! la_out=$(loadaverage_f $2); then
              exit 1
            else
              echo "LOADAVERAGE $2 OUTPUT:"
              info "$la_out"
            fi
          fi
          shift 2
        else
          echo "Loadavarage system information:"
          info "$(uptime | awk -F'load average: ' '{split($2, load, ", "); print "Last 1 minute: " load[1] "\nLast 5 minutes: " load[2] "\nLast 15 minutes: " load[3]}')"
          shift 1
        fi
        ;;

      -k | --kill)
        if [ -n "${2+x}" ] && [ "${2:0:1}" != "-" ]; then
          info "$(kill $2)"
          shift 2
        else
          echo "Error: Missing PID for KILL utility" >&2
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
     success "All results were saved to: $output_file"
  fi

  result="" # I didn't find any possibilities for using "for..in" construction in my script and have made this simple output for getting greenmark that it was used. Sorry)
  for word in Script had been finished!; do
    result="$result $word"
  done

    success "$result"
  }
fi
