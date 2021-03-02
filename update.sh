#!/bin/sh

. ${XDG_CONFIG_HOME:-${HOME}/.config}/shite/common.rc


remove_title() {
	post_file="$1"
	cat "$post_file" | awk '{
	if (!(FNR==1) && !($0 ~ /^#.*\n/))
		print $0
	}'
}

gen_info() {
	post_created="$1"

	# a post is considered 'modified' when this script is run,
	# so use the current date
	post_modified="$(date '+%F')"

	printf '<p class="info">\n'
	printf 'created: %s<br>\n'  "$post_created"
	printf 'modified: %s<br>\n' "$post_modified"
	printf '</p>\n'
}

gen_post() {
	post_file="$1"

	post_title_md="$(head -n 1 "$post_file")"
	post_title_html="$(run_lowdown "$post_title_md")"
	post_content="$(run_lowdown "$(remove_title "$post_file")")"
	post_date_parsed="$(parse_fname "${post_file##*/}")"

	# START html
	printf '<!DOCTYPE html>\n'
	printf '<html lang="en">\n'

	# generate the head
	gen_head "$post_file" "$(md_title "$post_file") - ${site_name}"

	# START body
	printf '<body>\n'

	# generate navigation
	gen_nav

	printf '<main>\n'

	# add title
	printf '%s\n'   "$post_title_html"
	# add info block
	printf '%s\n\n' "$(gen_info "${post_date_parsed%%:*}")"
	# add article itself
	printf '%s\n'   "$post_content"

	printf '</main>\n'

	# generate page footer
	gen_footer "$post_file"

	# END body
	printf '</body>\n'

	# END html
	printf '</html>\n'
}

for post in ${site_root}/${posts_dir}/*.md; do
	post_html="${post%%.*}.html"

	# if the html for this .md exists; do not include in list
	if [ -f "$post_html" ]; then
		continue
	fi

	# skip file if it is excluded
	if is_excluded "$(basename "$post")"; then
		continue
	fi

	log "adding "$post"..."
	gen_post "$post" > "$post_html"
done
