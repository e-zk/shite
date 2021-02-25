#!/bin/sh

. ${XDG_CONFIG_HOME:-${HOME}/.config}/shite/common.rc


remove_title() {
	awk '{
	if (!(FNR==1) && !($0 ~ /^#.*\n/))
		print $0
	}'
}

gen_desc() {
	post_file="$1"
	head -n 3 "$post_file" | sed -e '/#.*/d' -e '/^$/d' | md_to_txt | tr -d '\n' | sed -e 's/\ *$//'
	printf ' [...]'
}

gen_head() {
	page_file="$1"
	page_title="$2"

	post_bname="$(basename "$page_file")"

	page_url="${base_url}/posts/${post_bname%%.*}.html"
	page_desc="$(gen_desc "$page_file")"

	printf '<head>\n'
	printf '<meta http-equiv="content-type" content="text/html; charset=utf-8">\n'
	printf '<meta name="viewport" content="width=device-width, initial-scale=1">\n'
	printf '<meta name="theme-color" content="#101010">\n'
	printf '<meta property="og:title" content="%s">\n' "${page_title:-${site_name}}"
	printf '<meta property="og:description" content="%s">\n' "${page_desc}"
	printf '<meta property="og:url" content="%s">\n' "$page_url"
	printf '<meta property="og:type" content="article">\n'
	printf '<link rel="icon" href="/favicon.svg">\n'
	printf '<link rel="alternate icon" href="/favicon.ico">\n'
	printf '<link rel="stylesheet" href="/style.css">\n'

	if [ -n "$page_title" ]; then
		printf '<title>%s - %s</title>\n' "$page_title" "$site_name"
	else
		printf '<title>%s</title>\n' "$site_name"
	fi

	printf '</head>\n'
}

gen_nav() {
	printf '<header>\n'
	printf '<nav>\n'
	printf '<a href="%s">%s</a>\n' "/" "$fqdn"
	printf '<span class="right">\n'
	printf '<a href="/posts/">blog</a>&nbsp;&nbsp;<a href="/lists/">lists</a>&nbsp;&nbsp;<a href="/about.html">about</a>\n'
	printf '</span>'
	printf '</nav>\n'
	printf '</header>\n'
}

gen_footer() {
	post_path="$1"

	post_pt="$(basename "${post_path%%.*}.md")"

	printf '<footer>\n'
	printf '<a href="%s/%s">plaintext</a>&nbsp;&nbsp;<a href="%s">onion</a>\n' "$base_url" "$post_pt" "$onion_url"
	printf '<span class="right">(c) zakaria <a href="https://creativecommons.org/licenses/by-sa/4.0/">cc by-sa</a></span>\n'
	printf '</footer>\n'
}

gen_info() {
	post_created="$1"
	post_modified="$2"

	printf '<p class="info">\n'
	printf 'created: %s<br>\n' "$post_created"
	printf 'modified: %s<br>\n' "$post_modified"
	printf '</p>\n'
}

gen_post() {
	post_file="$1"

	post_title_md="$(head -n 1 < "$post_file")"
	post_title_html="$(run_lowdown "$post_title_md")"
	post_content="$(run_lowdown "$(cat "$post_file" | remove_title)")"

	post_date_parsed="$(parse_fname "${post_file##*/}")"

	printf '<!DOCTYPE html>\n'
	printf '<html lang="en">\n'
	gen_head "$post_file" "$(echo "$post_title_md" | sed -E -e 's/^#\ (.*)/\1/g')"
	printf '<body>\n'
	gen_nav
	printf '<main>\n'
	printf '%s\n' "$post_title_html"
	printf '%s\n\n' "$(gen_info "${post_date_parsed%%:*}" "$(date '+%F')")"
	printf '%s\n' "$post_content"
	gen_footer
	printf '</main>\n'
	printf '</body>\n'
	printf '</html>\n'
}

for post in ${posts_dir}/*.md; do
	post_html="${post%%.*}.html"

	# if the html for this .md exists; do not include in list
	if [ -f "$post_html" ]; then
		continue
	fi

	if is_excluded "$(basename "$post")"; then
		continue
	fi

	log "adding "$post"..."
	gen_post "$post" > "$post_html"
done
