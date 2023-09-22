#!/bin/bash

diskutil list > /tmp/disk_list_prev.txt

validate_volume() {
    if [ -n "$1" ] && [ "$1" != "Macintosh HD" ] && [ -d "/Volumes/$1" ]; then
        echo 1
    else
        echo 0
    fi
}

get_volume() {
    volume_name_by_info=$(diskutil info "$1" | grep "Volume Name:" | awk -F ': ' '{print $2}' | sed -e 's/^[[:space:]]*//')
    volume_name_by_list=$(diskutil list | grep -A 3 "$1" | tail -n 1 | awk '{print substr($3, index($1,$3))}')
    validate_by_info=$(validate_volume "$volume_name_by_info")
    validate_by_list=$(validate_volume "$volume_name_by_list")

    if [ $validate_by_info -eq 1 ]; then
        echo $volume_name_by_info
    elif [ $validate_by_list -eq 1 ]; then
        echo $volume_name_by_list
    else
        echo 0
    fi
}

while :
do
    sleep 5

    diskutil list > /tmp/disk_list_curr.txt

    if ! cmp -s /tmp/disk_list_prev.txt /tmp/disk_list_curr.txt ; then
        echo "A change was detected in the storage devices..."

        sort /tmp/disk_list_prev.txt -o /tmp/disk_list_prev_sorted.txt
        sort /tmp/disk_list_curr.txt -o /tmp/disk_list_curr_sorted.txt
        new_disk=$(comm -23 /tmp/disk_list_curr_sorted.txt /tmp/disk_list_prev_sorted.txt | grep '/dev/disk' | awk '{print $1}')

        if [ -n "$new_disk" ]; then
            echo "Detected new disk ($new_disk)"
            new_volume_name=$(get_volume "$new_disk")
            new_volume="/Volumes/$new_volume_name"
            echo "Validate if the volume name exists: $new_volume_name"

            if [ "$new_volume_name" != "0" ]; then
                echo "A new volume mount was detected: $new_volume"
                dest_dir="$HOME/usb_backups/$new_volume_name/$(date '+%Y-%m-%d_%H-%M-%S')"
                mkdir -p "$dest_dir"
                rsync -avzh "$new_volume/" "$dest_dir/"
            else
                echo "Can't get the volume name from the $new_disk"
                echo "Create a log with the disk info..."
                diskutil list | grep -A 3 "$new_disk" > "/tmp/usbhook_$(date '+%Y-%m-%d_%H-%M-%S').txt"
                echo "The log was created in the following path /tmp/usbhook_$(date '+%Y-%m-%d_%H-%M-%S').txt"
            fi
        else
            echo "Wasn't detected new disk, retry in 5 seconds..."
        fi
    else
        echo "Wasn't detected new storage device, retry in 5 seconds..."
    fi

    mv /tmp/disk_list_curr.txt /tmp/disk_list_prev.txt
done
