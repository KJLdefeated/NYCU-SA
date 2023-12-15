#!/bin/sh

usage() {
    echo "hw2.sh -i INPUT -o OUTPUT [-c csv|tsv] [-j]" >&2;
    echo "" >&2;
    echo "Available Options:" >&2;
    echo "" >&2;
    echo "-i: Input file to be decoded" >&2;
    echo "-o: Output directory" 1>&2;
    echo "-c csv|tsv: Output files.[ct]sv" >&2;
    echo "-j: Output info.json" >&2;
    exit 2
}

Parse_file() {
	file=$(sed -e 's/>-\n/>-/g' "$1")
	fileCount=$(echo "$file" | grep 'type:' | grep -c ^)
	name=$(echo "$file" | grep 'name:' | sed -n -e 1p | cut -d ':' -f 2 | tr -d ' ')
	author=$(echo "$file" | grep 'author:' | sed -n -e 1p | cut -d ':' -f 2 | tr -d ' ')
	date=$(echo "$file" | grep 'date:' | sed -n -e 1p | cut -d ':' -f 2 | tr -d ' ')

	if $output_info; then
		#real_date=$(date -Iseconds -r "${date}")
		printf "{\n\t\"name\": \"%s\",\n\t\"author\": \"%s\",\n\t\"date\": %s\n}" "${name}" "${author}" "${date}" >> "${output_dir}"/info.json  
	fi

	for idx in $(seq 1 "$fileCount"); do
		#echo $1
		file=$(sed -e 's/>-\n/>-/g' "$1")
		filename=$(echo "$file" | grep 'name:' | sed -n -e $((idx + 1))p | cut -d ':' -f 2 | tr -d ' ')
		data=$(echo "$file" | grep 'data:' | sed -n -e "${idx}"p | cut -d ':' -f 2 | tr -d ' ')
		type=$(echo "$file" | grep 'type:' | sed -n -e "${idx}"p | cut -d ':' -f 2 | tr -d ' ')
		md5=$(echo "$file" | grep 'md5:' | sed -n -e "${idx}"p | cut -d ':' -f 2 | tr -d ' ')
		sha=$(echo "$file" | grep 'sha-1:' | sed -n -e "${idx}"p | cut -d ':' -f 2 | tr -d ' ')
		pathCount=$(echo "${filename}" | grep -o "/" | wc -l | tr -d ' ')
		if [ "$pathCount" -gt 0 ]; then
			path=$(echo "${filename}" | cut -d "/" -f 1-"${pathCount}")
			mkdir -p "${output_dir}"/"${path}"
		fi

		decoded=$(echo "$data" | base64 -d)
		echo "$decoded" > "${output_dir}"/"$filename"
		realMd5=$(md5sum "${output_dir}"/"$filename" | cut -d " " -f 1)
		realSha=$(sha1sum "${output_dir}"/"$filename" | cut -d " " -f 1)
		size=$(wc -c "${output_dir}"/"$filename" | awk '{$1=$1;print}' | cut -d " " -f 1)
		if [ "$output_type" = "csv" ]; then
			echo "${filename}${dia}${size}${dia}${md5}${dia}${sha}" >> "${output_dir}"/files."${output_type}"   
		elif [ "$output_type" = "tsv" ]; then
			printf "%s\t%s\t%s\t%s\n" "${filename}" "${size}" "${md5}" "${sha}" >> "${output_dir}"/files."${output_type}" 
		fi

		if [ "$md5" != "$realMd5" ] || [ "$sha" != "$realSha" ] ; then
			invalidCount=$(( invalidCount + 1 ))
		fi

		# Recursive Decoding
		if [ "$type" = "hw2" ] && [ "$output_type" != "csv" ] && [ "$output_type" != "tsv" ] && [ $output_info = false ]; then
			#_file=$(sed -e 's/>-\n/>-/g' "${output_dir}"/"$filename")
			#_fileCount=$(echo "$_file" | grep 'type:' | grep -c ^)
			Parse_file "${output_dir}"/"$filename"
		fi

	done

	#for idx in $(seq 1 "$rec_count"); do
	#	Parse_file "${output_dir}"/"$filename"
	#done
}

output_info=false
output_type=""

while getopts ":i:o:c:j" argv; do
	case $argv in
		i) input_file=$OPTARG;;
		o) output_dir=$OPTARG;;
		c) output_type=$OPTARG;;
		j) output_info=true;;
		?) usage;;
	esac
done

if [ -z "$input_file" ] || [ -z "$output_dir" ]; then
	usage
fi

if [ "$output_type" = "csv" ];then
	dia=","
elif [ "$output_type" = "tsv" ];then
	dia="\t"
fi

mkdir -p "$output_dir"

if [ "$output_type" = "csv" ];then
	touch "${output_dir}"/files."${output_type}"
	printf "filename,size,md5,sha1\n" >> "${output_dir}"/files."${output_type}"
elif [ "$output_type" = "tsv" ];then
	touch "${output_dir}"/files."${output_type}"
	printf "filename\tsize\tmd5\tsha1\n" >> "${output_dir}"/files."${output_type}"
fi

invalidCount=0

#_file=$(sed -e 's/>-\n/>-/g' "$input_file")
#_fileCount=$(echo "$_file" | grep 'type:' | grep -c ^)

Parse_file "$input_file"

exit "$invalidCount"
