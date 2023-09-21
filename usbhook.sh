#!/bin/bash

diskutil list > /tmp/disk_list_prev.txt

while :
do
    sleep 5

    diskutil list > /tmp/disk_list_curr.txt

    if ! cmp -s /tmp/disk_list_prev.txt /tmp/disk_list_curr.txt ; then
        sort /tmp/disk_list_prev.txt -o /tmp/disk_list_prev_sorted.txt
        sort /tmp/disk_list_curr.txt -o /tmp/disk_list_curr_sorted.txt
        new_disk=$(comm -23 /tmp/disk_list_curr_sorted.txt /tmp/disk_list_prev_sorted.txt | grep '/dev/disk' | awk '{print $1}')

        if [ -n "$new_disk" ]; then
            echo "Detected new disk ($new_disk)"
            new_volume=$(diskutil list "$new_disk" | grep -E 'Apple_HFS|Apple_APFS|Microsoft Basic Data|DOS_FAT_32' | awk '{print $3}')

            if [ -n "$new_volume" ]; then
                echo "New localized volume /Volumes/$new_volume"
                dest_dir="$HOME/USB_Backups/$(date '+%Y-%m-%d_%H-%M-%S')"
                mkdir -p "$dest_dir"
                rsync -avh "/Volumes/$new_volume/" "$dest_dir/"
            fi
        fi
    fi

    mv /tmp/disk_list_curr.txt /tmp/disk_list_prev.txt
done
