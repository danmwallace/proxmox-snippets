#!/bin/bash

# Modify these variables to suit your needs
VM_STORAGE="{{ VM_STORAGE }}"
ISO_STORAGE="/mnt/pve/local/template/iso"
ISO_URL="https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"

# ID to be used for the Template and for the test machine creeated by --test function
TEMPLATE_ID="9000"
TEST_VM_ID="9001"

main() {
    case "$1" in
        --generate)
            wget -P ${ISO_STORAGE} ${ISO_URL}
            LOCAL_ISO="${ISO_STORAGE}/ubuntu-24.04-server-cloudimg-amd64.img"

            printf "[QEMU VM TEMPLATE SCRIPT] - Creating Ubuntu 24.04 LTS cloud image\n"
            qm destroy "${TEMPLATE_ID}"
            qm create "${TEMPLATE_ID}" --name "ubuntu-2404-template" --memory 4096 --cores 4 --net0 virtio,bridge=vmbr1
            qm importdisk "${TEMPLATE_ID}" "${LOCAL_ISO}" "${VM_STORAGE}"
            qm set "${TEMPLATE_ID}" --scsihw virtio-scsi-pci --scsi0 "${VM_STORAGE}":vm-"${TEMPLATE_ID}"-disk-0
            qm set "${TEMPLATE_ID}" --boot c --bootdisk scsi0
            qm set "${TEMPLATE_ID}" --ide2 "${VM_STORAGE}":cloudinit
            qm set "${TEMPLATE_ID}" --serial0 socket --vga serial0
            qm set "${TEMPLATE_ID}" --agent enabled=1
            qm set "${TEMPLATE_ID}" --cicustom "user=local:snippets/user-data.yml"
            qm set "${TEMPLATE_ID}" --ipconfig0 ip=dhcp
            qm template "${TEMPLATE_ID}"
            printf "[QEMU VM TEMPLATE SCRIPT] - End of Ubuntu Server 24.04 LTS template rebuild.\n"
        ;;
        --test)
            # Create an example virtual machine to test
            printf "[QEMU VM TEMPLATE SCRIPT] - Attempting to create clone example\n"
            qm clone "${TEMPLATE_ID}" "${TEMPLATE_ID}"1 --full true --name test --storage "${VM_STORAGE}"
            qm start "${TEST_VM_ID}"
            printf "[QEMU VM TEMPLATE SCRIPT] - Please review container ID %s" "${TEST_VM_ID}"
        ;;
        --help)
           printf "create-template \n \n"
           printf "Usage: \n"
           printf "create-template --generate | --test"
           printf "\n"
           printf "How to use..."
           printf "--generate : Downloads a cloud image of your choice (modify $ISO_URL within script) and modify it for you, injecting your user-data.yml file found in your snippets directory on proxmox"
           printf "--test : Generates a test QEMU VM on proxmox with default ID of 9001 to test the created template."
        ;;
    esac
}

main "$@"