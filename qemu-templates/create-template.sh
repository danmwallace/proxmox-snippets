#!/bin/bash

# Modify these variables to suit your needs
VM_STORAGE="local-zfs"
ISO_STORAGE="/mnt/pve/local/template/iso"
ISO_URL="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"

# ID to be used for the Template and for the test machine creeated by --test function
TEMPLATE_ID="${TEMPLATE_ID}"
TEST_VM_ID="${TEST_VM_ID}"

main {
    case "$1" in
        --generate)
            # Uncomment to download new file
            # You will need to adjust these to whereever your iso storage location is
            # wget -P ${ISO_STORAGE} ${ISO_URL}
            LOCAL_ISO="${ISO_STORAGE}/ubuntu-24.04-server-cloudimg-amd64.img"

            printf "[QEMU VM TEMPLATE SCRIPT] - Creating Ubuntu 24.04 LTS cloud image\n"
            qm destroy ${TEMPLATE_ID}
            qm create ${TEMPLATE_ID} --name "ubuntu-2404-template" --memory 4096 --cores 4 --net0 virtio,bridge=vmbr1
            qm importdisk ${TEMPLATE_ID} ${LOCAL_ISO} local-zfs
            qm set ${TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-${TEMPLATE_ID}-disk-0
            qm set ${TEMPLATE_ID} --boot c --bootdisk scsi0
            qm set ${TEMPLATE_ID} --ide2 local-zfs:cloudinit
            qm set ${TEMPLATE_ID} --serial0 socket --vga serial0
            qm set ${TEMPLATE_ID} --agent enabled=1
            qm set ${TEMPLATE_ID} --cicustom "user=local:snippets/user-data.yml"
            qm set ${TEMPLATE_ID} --ipconfig0 ip=dhcp
            #qm set ${TEMPLATE_ID} --sshkey ./id_ed25519.pub
            qm template ${TEMPLATE_ID}
            printf "[QEMU VM TEMPLATE SCRIPT] - End of Ubuntu Server 24.04 LTS template rebuild.\n"
        ;;
        --test)
            # Create an example virtual machine to test
            printf "[QEMU VM TEMPLATE SCRIPT] - Attempting to create clone example\n"
            qm clone ${TEMPLATE_ID} ${TEMPLATE_ID}1 --full true --name test --storage local-zfs
            qm start ${TEST_VM_ID}
            printf "[QEMU VM TEMPLATE SCRIPT] - Please review container ID ${TEST_VM_ID}"
        ;;
        --help)
           printf "create-template \n \n"
           printf "Usage: \n"
           printf "create-template --generate | --test
    esac
}

main "$@"