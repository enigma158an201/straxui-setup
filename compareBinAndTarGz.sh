#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
	echo "Usage: $0 </path/to/binary_on_disk> </path/to/file.tar.gz> <binary_in_tar.gz>"
	exit 1
fi

# Assign the script arguments to variables # Define the paths to the tar.gz archive and the binary file on disk
binary_on_disk="$1" #binary_on_disk="/media/CommonData/telechargements/stratisEVM/beacon-chain" #"path/to/binary/on/disk"
tar_gz_file="$2"	#tar_gz_file="/media/CommonData/telechargements/stratisEVM/beacon-chain-linux-amd64-4032333.tar.gz" #"your_archive.tar.gz"
binary_in_tar="$3"	#binary_in_tar="beacon-chain" #"path/to/binary/in/tar.gz"

main() {																			# Extract the binary file from the tar.gz archive to a temporary directory
	temp_dir=$(mktemp -d)															# Create a temporary directory

	# Extract the binary file from the tar.gz archive to the temporary directory & Check if the extraction was successful
	tar -xzvf "${tar_gz_file}" -C "${temp_dir}" "${binary_in_tar}" 2>/dev/null || ( echo "Error: Failed to extract binary from the tar.gz file."; exit 1 )

	if cmp -s "${temp_dir}/${binary_in_tar}" "${binary_on_disk}"; then					# Compare the binary files using the `cmp` command & Check the exit status to determine if the files are the same
		echo "Binary files are the same."
	else
		echo "Binary files are different."
	fi

	rm -rf "${temp_dir}"																# Clean up temporary directory
}
main