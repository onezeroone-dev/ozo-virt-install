#!/bin/bash
# Script Name: ozo-virt-install.sh
# Version    : 1.0.0
# Description: This script assists with virtual server deployment using virt-install to define and start a guest (domain) on a Linux KVM host.
# Usage      : /usr/sbin/ozo-virt-install.sh /path/to/guest.conf
# Author     : Andy Lievertz <alievertz@onezeroone.dev>

# FUNCTIONS
function ozo-log {
    # Function   : ozo-log
    # Description: Logs output to the system log
    # Arguments  :
    #   LEVEL    : The log level. Allowed values are "err", "info", or "warning". Defaults to "info".
    #   MESSAGE  : The message to log.

    # Determine if LEVEL is null
    if [[ -z "${LEVEL}" ]]
    then
        # Level is null; set to "info"
        LEVEL="info"
    fi
    # Determine if MESSAGE is not null
    if [[ -n "${MESSAGE}" ]]
    then
        # Message is not null; log the MESSAGE with LEVEL
        logger -p local0.${LEVEL} -t "OZO Rdiff-Backup" "${MESSAGE}"
    fi
}

function ozo-virt-install-validate-configuration {
    # Function   : ozo-virt-install-validate-configuration
    # Description: Performs a series of checks against the script configuration. Returns 0 (TRUE) if all checks pass and 1 (FALSE) if any check fails.

    # Control variable
    local RETURN=0
    # Determine if we are not root
    if [[ "$(id -u)" != "0" ]]
    then
        # We are not root; log
        LEVEL="err" MESSAGE="Please run this script as root." ozo-log
        RETURN=1
    fi
    # Determine if a configuration has been provided
    if [[ -n "${CONFIGURATION}" ]]
    then
        # Configuration provided; check that it exists
        if [[ -f "${CONFIGURATION}" ]]
        then
            # Configuration exists; source
            source "${CONFIGURATION}"
            # Dtermine if all user-defined variables are set
            for USERDEFVAR in OS_LOCATION OS_KICKSTART KVM_NETWORK KVM_NETDEV_MODEL VM_HOSTNAME VM_MEMORY VM_CPUS VM_DISK VM_IP VM_GATEWAY VM_NETMASK VM_NAMESERVER VM_NETDEV
            do
                if [[ -z "${!USERDEFVAR}" ]]
                then
                    LEVEL="err" MESSAGE="User-defined variable ${USERDEFVAR} is not set." ozo-log
                    RETURN=1
                fi
            done
            # Determine if the VM_DISK variable is defined
            if [[ -n "${VM_DISK}" ]]
            then
                # Variable is defined; determine if the device exists
                if [[ ! -b "${VM_DISK}" ]]
                then
                    LEVEL="err" MESSAGE="VM disk device ${VM_DISK} does not exist." ozo-err
                    RETURN=1
                fi
            fi
            # Set default value for MAC_OPTION
            MAC_OPTION=""
            # Determine if VM_MAC is not null
            if [[ -n ${VM_MAC} ]]
            then
                # VM_MAC is not null; set MAC_OPTION
                MAC_OPTION=",mac=${VM_MAC}"
            fi
            # Iterate through the required binaries
            for BINARY in virsh virt-install systemctl
            do
                # Determine if the required binary is not present
                if ! which ${BINARY}
                then
                    # Required binary is not present; log
                    LEVEL="err" MESSAGE="Missing ${BINARY} binary." ozo-log
                    RETURN=1
                fi
            done
            # Iterate through the required services
            for SERVICE in libvirtd
            do
                # Determine if the required service is not running
                if ! systemctl is-active --quiet ${SERVICE}
                then
                    # Required service is not running; log
                    LEVEL="warning" MESSAGE="The ${SERVICE} service is not running; attempting to start." ozo-log
                    # Determine if attempting to start the service fails
                    if ! systemctl start --quiet ${SERVICE}
                    then
                        # Attempting to start the service fails
                        LEVEL="err" MESSAGE="Unable to start ${SERVICE}." ozo-log
                        RETURN=1
                    fi
                fi
            done
        else
            # Configuration file does not exist; log
            LEVEL="err" MESSAGE="Cannot find/read configuration file ${1}." ozo-log
            RETURN=1
        fi
    else
        # Configuration file is not specified; log
        LEVEL="err" MESSAGE="Please specify a configuration file e.g., ${0} /path/to/guest.conf" ozo-log
        RETURN=1
    fi
    # Return
    return ${RETURN}
}

function ozo-virt-install {
    # Function   : ozo-virt-install
    # Description: Performs the virt-install for a given configuration. Returns 0 (TRUE) if the virt-install succeeds and 1 (FALSE) if it fails.

    # Control variable
    local RETURN=0
    # Determine if the configuration validates
    if ozo-virt-install-validate-configuration
    then
        # Configuration validates; log
        LEVEL="info" MESSAGE="Configuration validates. Attempting to virt-install ${VM_HOSTNAME}." ozo-log
        # Determine if virt-install is successful
        if virt-install --name ${VM_HOSTNAME} --memory ${VM_MEMORY} --vcpus ${VM_CPUS} --location ${OS_LOCATION} --disk path=${VM_DISK} --network network=${KVM_NETWORK},model=${KVM_NETDEV_MODEL}${MAC_OPTION} --noautoconsole --extra-args "inst.ks=${OS_KICKSTART} inst.text console=ttyS0,115200n8 ip=${VM_IP}::${VM_GATEWAY}:${VM_NETMASK}:${VM_HOSTNAME}:${VM_NETDEV}:none nameserver=${VM_NAMESERVER}" --graphics none --boot menu=on
        then
            # virt-install is successful
            LEVEL="info" MESSAGE="Successfully virt-installed ${VM_HOSTNAME}." ozo-log
            # Determine if autostart is set for VM
            if virsh autostart ${VM_HOSTNAME}
            then
                # Autostart is set for VM; log
                LEVEL="info" MESSAGE="Set guest ${VM_HOSTNAME} autostart = TRUE." ozo-log
            else
                # Autostart is not set for VM; log
                LEVEL="err" MESSAGE="Unable to set guest ${VM_HOSTNAME} autostart = TRUE." ozo-log
                RETURN=1
            fi
            # List all VMs
            virsh list --all
            # Display a helpful message
            echo "To interact with your new VM, execute \"virsh console ${VM_HOSTNAME}\""
        else
            # virt-install failed;
            LEVEL="err" MESSAGE="Error performing virt-install." ozo-log
            RETURN=1
            # Clean up the failed VM
            virsh destroy ${VM_HOSTNAME}
            virsh undefine ${VM_HOSTNAME}
        fi
    else
        # Configuration does not validate
        LEVEL="err" MESSAGE="Error validating configuration." ozo-log
        RETURN=1
    fi
    # Return
    return ${RETURN}
}

# MAIN
# Control variable
EXIT=0
# Set variables
CONFIGURATION="${1}"
# Log a process start message
LEVEL="info" MESSAGE="OZO Virt-Install starting process." ozo-log
# Determine if ozo-virt-install is successful
if ozo-virt-install > /dev/null 2>&1
then
    # ozo-virt-install was successful
    LEVEL="info" MESSAGE="OZO Virt-Install finished with success." ozo-log
else
    # ozo-virt-install failed
    LEVEL="err" MESSAGE="OZO Virt-Install finished with errors." ozo-log
    EXIT=1
fi
# Log a process complete message
LEVEL="info" MESSAGE="OZO Virt-Install process complete." ozo-log
# Exit
exit ${EXIT}
