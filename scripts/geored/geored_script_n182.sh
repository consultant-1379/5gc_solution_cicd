#!/bin/bash


################################

# Define global variables to store eccd credentials ** Double check details **
server_eccd="eccd@214.7.248.10"
password_eccd="DefaultP12345!"

# Define global variables to store namespace ** Double check details **
namespace="ccdm"

# Define global variables to store ccdm credentials ** Double check details **
server_ccdm="ccdmoam@ccdm1-n182.seli.gic.ericsson.se"
password_ccdm="WeakPas#worD-1"

# Define a global variable to store the filename - ** will be populated at runtime **
filename_to_use=""

################################

# Define a function to encapsulate the 'expect' logic for eccd
function run_expect_script_eccd() {
    expect -c "

        set server \"$server_eccd\"
        set password \"$password_eccd\"
        spawn ssh -o \"StrictHostKeyChecking no\" \$server

        expect {
            \"The authenticity of host\" {
                send \"yes\r\"
                exp_continue
            }
            \"assword:\" {
                send \"\$password\r\"
            }
            timeout {
                send_user \"Timeout or unexpected prompt\n\"
                exit 1
            }
        }

        expect {
            -re \".*>\" {
                send \"kubectl get pods -n $namespace --sort-by='.status.containerStatuses\\[0\\].restartCount'\r\"
            }
            timeout {
                send_user \"Timeout waiting for the shell prompt\n\"
                exit 1
            }
        }





        expect {
            -re \".*>\" {
                send \"kubectl get pods -A | egrep -iv 'Running|Completed|Succeeded'\r\"
            }
            timeout {
                send_user \"Timeout waiting for the shell prompt\n\"
                exit 1
            }
        }

        expect {
    -re \".*>\" {
        send \"kubectl get nodes\r\"
    }
    timeout {
        send_user \"Timeout waiting for the shell prompt\n\"
        exit 1
            }
    }

        expect -re \".*>\"
        send \"exit\r\"

        expect eof
    "
}

# Define a function to encapsulate the 'expect' logic for ccdm
function run_expect_script_ccdm() {
    expect -c "
        set server \"$server_ccdm\"
        set password \"$password_ccdm\"


        spawn ssh -o \"StrictHostKeyChecking no\" \$server

        expect {
            \"The authenticity of host\" {
                send \"yes\r\"
                exp_continue
            }
            \"assword:\" {
                send \"\$password\r\"
            }
            timeout {
                send_user \"Timeout or unexpected prompt\n\"
                exit 1
            }
        }

        expect {
            -re \".*#\" {
                send \"show alarm\r\"
            }
            timeout {
                send_user \"Timeout waiting for the shell prompt\n\"
                exit 1
            }
        }

        expect {
            -re \".*#\" {
                send \"show alarm-history\r\"
            }
            timeout {
                send_user \"Timeout waiting for the shell prompt\n\"
                exit 1
            }
        }

        expect -re \".#\"
        send \"exit\r\"

        expect eof
    "
}


# Define a function to encapsulate the file creation steps

function handle_output_filename() {
    # Get the current date and time in the format YYYY-MM-DD_HH-MM-SS
    local current_datetime=$(date +"%Y-%m-%d_%H-%M-%S")

    # Define the filename with the date and time stamp, located in the script's directory
    local filename_output="geoRed_check_output_$current_datetime.txt"

    # Check if any file matching the pattern exists
    local existing_file=$(ls geoRed_check_output_*.txt 2> /dev/null | head -n 1)

    if [ -n "$existing_file" ]; then
        filename_to_use="$existing_file"
    else
        filename_to_use="$filename_output"
    fi

    echo "$filename_to_use"
}

##############
##   Main   ##
##############


filename_to_use=$(handle_output_filename)
echo "The output filename to use is: $filename_to_use"



# Create or append to the output file and write echo statements to it
{
  echo
  echo "**************************************************************"
  echo "**************************************************************"
  echo "*** Timestamp for GeoRed check: $(date)"
  echo "**************************************************************"
  echo "**************************************************************"
  echo

  echo
  echo "**************************************************************"
  echo "*******         Kubernetes Node / Pod Info:        ***********"
  echo "**************************************************************"
  echo

eccdCheck=$(run_expect_script_eccd)
echo "$eccdCheck"



  echo
  echo "**************************************************************"
  echo "****      Active alarm / Alarm History info:           *******"
  echo "**************************************************************"
  echo

alarmCheck=$(run_expect_script_ccdm)
echo "$alarmCheck"



  echo
  echo "Script execution completed."
  echo
} | tee -a "$filename_to_use"

# Print a confirmation message to the console
echo "The output was created and written to '$filename_to_use'."
