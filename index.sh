#!/bin/sh

. ${XDG_CONFIG_HOME:-${HOME}/.config}/shite/common.rc


# retreive list of posts in reverse chronological order
# TODO: this might out output stuff in the proper order every time
get_posts() {
	for post in ${site_root}/${posts_dir}/*.html; do
		if is_excluded "$(basename "$post")"; then
			continue
		fi
		echo "$post"
	done | tail -r
}

gen_index() {
	# START html
	printf '<!DOCTYPE html>\n'
	printf '<html lang="en">\n'

	# generate the head
	gen_head "$post_file" "${site_name}"

	# START body
	printf '<body>\n'

	# generate navigation
	gen_nav

	printf '<main>\n'

	# print stuff
	cat "${html_dir}/posts.html"

	# list posts
	printf '<ul class="postslist">\n'
	for post in $(get_posts); do
		log "adding "$post" to index..."

		post_md="${post%%.*}.md"
		post_url="$(basename "$post")"
		date_parsed="$(parse_fname "$post_url")"
		post_title="$(md_title "$post_md" | md_to_txt)"
		post_date="${date_parsed%%:*}"

		printf '<li>\n'
		printf '<a href="%s"><span class="right postdate">%s</span>%s</a>\n' "$post_url" "$post_date" "$post_title"
		printf '</li>\n'
	done
	printf '</ul>\n'
	printf '</main>\n'

	# END body
	printf '</body>\n'

	# END html
	printf '</html>\n'
}

gen_index > "$posts_index"
