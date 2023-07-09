#!/bin/bash

function ozo-log {
  ### Logs output to the system log
  if [[ -z "${LEVEL}" ]]
  then
    LEVEL="info"
  fi
  if [[ -n "${MESSAGE}" ]]
  then
    logger -p local0.${LEVEL} -t "OZO Virt-Install" "${MESSAGE}"
  fi
}

function ozo-virt-install-validate-configuration {
  ### Performs a series of checks against the script configuration
  ### Returns 0 (TRUE) if all checks pass and 1 (FALSE) if any check fails
  local RETURN=0
  # check if we are root
  if [[ "$(id -u)" != "0" ]]
  then
    # we are not root; log
    LEVEL="err" MESSAGE="Please run this script as root." ozo-log
    RETURN=1
  fi
  # check that a configuration has been provided
  if [[ -n "${CONFIGURATION}" ]]
  then
    # configuration provided; check that it exists
    if [[ -f "${CONFIGURATION}" ]]
    then
      # exists; source
      source "${CONFIGURATION}"
      # check that all user-defined variables are set
      for USERDEFVAR in OS_LOCATION OS_KICKSTART KVM_NETWORK KVM_NETDEV_MODEL VM_HOSTNAME VM_MEMORY VM_CPUS VM_DISK VM_IP VM_GATEWAY VM_NETMASK VM_NAMESERVER VM_NETDEV
      do
        if [[ -z "${!USERDEFVAR}" ]]
        then
          LEVEL="err" MESSAGE="User-defined variable ${USERDEFVAR} is not set." ozo-log
          RETURN=1
        fi
      done
      # check that the VM_DISK variable is defined
      if [[ -n "${VM_DISK}" ]]
      then
        # defined; check that the device exists
        if [[ ! -b "${VM_DISK}" ]]
        then
          LEVEL="err" MESSAGE="VM disk device ${VM_DISK} does not exist." ozo-err
          RETURN=1
        fi
      fi
      # populate MAC_OPTION if VM_MAC has a value
      MAC_OPTION=""
      if [[ -n ${VM_MAC} ]]
      then
        MAC_OPTION=",mac=${VM_MAC}"
      fi
      # check that all required binaries are present
      for BINARY in virsh virt-install systemctl
      do
        if ! which ${BINARY}
        then
          LEVEL="err" MESSAGE="Missing ${BINARY} binary." ozo-log
          RETURN=1
        fi
      done
      # check that all required services are running
      for SERVICE in virtqemud virtnetworkd virtnodedevd virtsecretd virtstoraged virtinterfaced
      do
        if ! systemctl is-active --quiet ${SERVICE}
        then
          LEVEL="warning" MESSAGE="The ${SERVICE} service is not running; attempting to start." ozo-log
          if ! systemctl start --quiet ${SERVICE}
          then
            LEVEL="err" MESSAGE="Unable to start ${SERVICE}." ozo-log
            RETURN=1
          fi
        fi
      done
    else
      # does not exist; log
      LEVEL="err" MESSAGE="Cannot find/read configuration file ${1}." ozo-log
      RETURN=1
    fi
  else
    # not specified; log
    LEVEL="err" MESSAGE="Please specify a configuration file e.g., ${0} /path/to/guest.conf" ozo-log
    RETURN=1
  fi
  return ${RETURN}
}

function ozo-virt-install {
  ### Performs the virt-install for a given configuration
  ### Returns 0 (TRUE) if the virt-install succeeds and 1 (FALSE) if it fails
  local RETURN=0
  if ozo-virt-install-validate-configuration
  then
    # all checks passed; log
    LEVEL="info" MESSAGE="Configuration validates. Attempting to virt-install ${VM_HOSTNAME}." ozo-log
    # attempt to virt-install
    if virt-install --name ${VM_HOSTNAME} --memory ${VM_MEMORY} --vcpus ${VM_CPUS} --location ${OS_LOCATION} --disk path=${VM_DISK} --network network=${KVM_NETWORK},model=${KVM_NETDEV_MODEL}${MAC_OPTION} --noautoconsole --extra-args "inst.ks=${OS_KICKSTART} inst.text console=ttyS0,115200n8 ip=${VM_IP}::${VM_GATEWAY}:${VM_NETMASK}:${VM_HOSTNAME}:${VM_NETDEV}:none nameserver=${VM_NAMESERVER}" --graphics none --boot menu=on
    then
      LEVEL="info" MESSAGE="Successfully virt-installed ${VM_HOSTNAME}." ozo-log
      if virsh autostart ${VM_HOSTNAME}
      then
        LEVEL="info" MESSAGE="Set guest ${VM_HOSTNAME} autostart = TRUE." ozo-log
      else
        LEVEL="err" MESSAGE="Unable to set guest ${VM_HOSTNAME} autostart = TRUE." ozo-log
        RETURN=1
      fi
      virsh list --all
      echo "To interact with your new VM, execute \"virsh console ${VM_HOSTNAME}\""
    else
      # virt-install failed; 
      LEVEL="err" MESSAGE="Error performing virt-install." ozo-log
      RETURN=1
      # attempt to clean up
      virsh destroy ${VM_HOSTNAME}
      virsh undefine ${VM_HOSTNAME}
    fi
  else
    LEVEL="err" MESSAGE="Error validating configuration." ozo-log
    RETURN=1
  fi
  return ${RETURN}
}

# Main

EXIT=0
CONFIGURATION="${1}"

LEVEL="info" MESSAGE="Starting OZO Virt-Install." ozo-log
if ozo-virt-install > /dev/null 2>&1
then
  LEVEL="info" MESSAGE="OZO Virt-Install finished with success." ozo-log
else
  LEVEL="err" MESSAGE="OZO Virt-Install finished with errors." ozo-log
  EXIT=1
fi

exit ${EXIT}
