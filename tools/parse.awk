#!/bin/awk -f

#######################################
#                                     #
#  Minetest Forum Recovery Project    #
#  by sorcerykid                      #
#                                     #
#######################################

# Reformat a cached page using templates for the header, body, and footer.
#
# Other modes can be specified with the 'mode' parameter:
#   - parse - reformat the cached page and save the version to the 'pages' directory
#   - compile - compile a tab-delimited digest of posts for importing to a spreadsheet
#   - extract - extract posts from the cached page and save to the 'posts' directory
#   - debug - print the values of all variables obtained from parsing the cached page
#   - check - validate the cached page and print an error message on parsing failure
#
# Example usage with single cached page:
#   % ./parse.awk -v mode=debug cache/3_1568.htm
#
# Example usage with directory of cached pages:
#   % find cache -name "*.htm" -exec ./parse.awk {} \;
#   % find cache -name "*.htm" -exec ./parse.awk -v mode=compile {} > digest.txt \;

function abort( msg ) {
	status = 1;
	if( msg ) print( msg );
	exit;
}

function convert_clock( clock, _hh, _pp ) {
	match( clock, /(... ... .., ....) (..?):(..)/, res )

	_hh = res[ 2 ];
	_pp = _hh >= 12 ? "pm" : "am";

	if( _hh > 12 )
		_hh = _hh - 12;
	else if( _hh == 0 )
		_hh = 12;
	end
	return sprintf( "%s %d:%02d %s", res[ 1 ], _hh, res[ 3 ], _pp );
}

# TODO: this only needs to be called once!
function get_page_path( ) {
	return page_count == 1 ? "pages/" forum_id "_" topic_id ".htm" : "pages/" forum_id "_" topic_id "_" ( ( page_count - 1 ) * 25 ) ".htm";
}

function get_target_file( path ) {
	return path gensub( ".*/", "", "g", FILENAME );
}

function inject_global_vars( ) {
	gsub( /%PAGE_PATH%/, get_page_path( ) );
	gsub( /%FORUM_TITLE%/, forum_title );
	gsub( /%FORUM_ID%/, forum_id );
	gsub( /%TOPIC_TITLE%/, topic_title );
	gsub( /%TOPIC_ID%/, topic_id );
	gsub( /%PAGE_COUNT%/, page_count );
	gsub( /%PAGE_TOTAL%/, page_total );
	gsub( /%POST_TOTAL%/, post_total );
	gsub( /%ROBOT_NAME%/, robot_name );
	gsub( /%ROBOT_URL%/, robot_url );
	gsub( /%CACHE_DATE%/, cache_date );
}

function inject_local_vars( text ) {
        # https://www.gnu.org/software/gawk/manual/html_node/Gory-Details.html
        gsub( /&/, "\\\\\\&", post_content );
        gsub( /&/, "\\\\\\&", post_title );

	gsub( /%PAGE_PATH%/, get_page_path( ), text );
	gsub( /%POST_ID%/, post_id, text );
	gsub( /%POST_CLASS%/, post_count % 2 == 0 ? "bg1" : "bg2", text );
	gsub( /%POST_SUBCLASS%/, post_count == 1 && page_count == 1 ? "first" : "", text );
	gsub( /%POST_TITLE%/, post_title, text );
	gsub( /%POST_DATE%/, post_date, text );
	gsub( /%AUTHOR_NAME%/, author_name, text );
	gsub( /%AUTHOR_RANK%/, author_rank, text );
	gsub( /%AUTHOR_POST_TOTAL%/, author_post_total, text );
	gsub( /%AUTHOR_JOIN_DATE%/, author_join_date, text );
	if( author_github_handle ) {
		gsub( /%AUTHOR_GITHUB_HANDLE%/, author_github_handle, text );
		gsub( /<\/?HAS_GITHUB_HANDLE>/, "", text );
	}
	else {
		gsub( /<HAS_GITHUB_HANDLE>(.*)<\/HAS_GITHUB_HANDLE>/, "", text );
	}
	if( author_player_handle ) {
		gsub( /%AUTHOR_PLAYER_HANDLE%/, author_player_handle, text );
		gsub( /<\/?HAS_PLAYER_HANDLE>/, "", text );
	}
	else {
		gsub( /<HAS_PLAYER_HANDLE>(.*)<\/HAS_PLAYER_HANDLE>/, "", text );
	}
	gsub( /%POST_CONTENT%/, post_content, text );
	return text;
}

function strip_highlights( ) {
	$0 = gensub( /<a name='YANDEX_[0-9]+'><\/a>&nbsp;<span class='highlight highlight_active'>&nbsp;/, "", "g" );
	$0 = gensub( /&nbsp;<\/span><a href='[^#]+#YANDEX_[0-9]+'><\/a><\/nobr>/, "", "g" );
	$0 = gensub( /&nbsp;<\/span><\/A><a href='[^#]+#YANDEX_[0-9]+'><\/a><\/nobr>/, "", "g" );

        $0 = gensub( /<a name='YANDEX_[0-9]+'><\/a><nobr><a href='[^#]+#YANDEX_[0-9]+'><\/a><a href="[^"]+">/, "", "g" );
        $0 = gensub( /<a name='YANDEX_[0-9]+'><\/a><nobr><a href='[^#]+#YANDEX_[0-9]+'><\/a>/, "", "g" );
	$0 = gensub( /<span class='highlight highlight_active'>&nbsp;/, "", "g" );
	$0 = gensub( /&nbsp;<\/span><a name='YANDEX_LAST'><\/a>/, "", "g" );
	$0 = gensub( /<script src="\/\/yandex.st\/.+" type="text\/javascript"><\/script>/, "", "g" );
	$0 = gensub( /<a name='yandex_top'><\/a><script>.+<\/script>/, "", "g" );

	return $0;
}

BEGIN {
	if( !mode ) mode = "parse";

	split( "Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec", to_months );

	while( ( getline < "templates/body.htm" ) > 0 ) {
		body = body $0 "\n";
	}
	OFS = "\t";
}

{
	strip_highlights( );

	if( NR == 1 && match( $0, /__google-cache-hdr.+ appeared on ([A-Z][a-z][a-z]) ([0-9][0-9]?), ([0-9][0-9][0-9][0-9]) /, res ) ) {
		# date format: MMM DD, YYYY
		robot_name = "Google Bot";
		robot_url = "https://google.com/";
		cache_date = res[ 2 ] "-" res[ 1 ] "-" res[ 3 ];
		match_count++;
	}
	else if( NR == 1 && match( $0, /<!--InvariantDate:([0-9][0-9]?)\/([0-9][0-9]?)\/([0-9][0-9][0-9][0-9])-->/, res ) ) {
		# date format: MM/DD/YYYY
		robot_name = "Bing Bot";
		robot_url = "https://bing.com/";
		cache_date = res[ 2 ] "-" to_months[ res[ 1 ] + 0 ] "-" res[ 3 ];
		match_count++;
	}
	else if( NR == 2 && match( $0, /<script>.+\.date = '([0-9][0-9]?)\.([0-9][0-9]?)\.([0-9][0-9][0-9][0-9]) /, res ) ) {		
		# date format: DD.MM.YYYY
		robot_name = "Yandex Bot";
		robot_url = "https://yandex.com/";
		cache_date = res[ 1 ] "-" to_months[ res[ 2 ] + 0 ] "-" res[ 3 ];
		match_count++;
	}
	else if( match( $0, /FILE ARCHIVED ON ..:..:.. (...) (..), (....) AND RETRIEVED/, res ) ) {	# TODO: need to check that we're at actual end of file
		# date format: MMM DD, YYYY
		robot_name = "Wayback Machine";
		robot_url = "https://archive.org/";
		cache_date = res[ 2 ] "-" res[ 1 ] "-" res[ 3 ];
		match_count++;
	}
	else if( match( $0, /<h2><a href="\.\/viewtopic.php\?f=([0-9]+)&amp;t=([0-9]+).*">(.+)<\/a>/, res ) ) {
		forum_id = res[ 1 ];
		topic_id = res[ 2 ];
		topic_title = res[ 3 ];
		match_count++;
	}
	else if( match( $0, /<p><\/p><p><a href=".+" class="left-box left" accesskey="r">Return to (.+)<\/a><\/p>/, res ) ) {
		forum_title = res[ 1 ];
		match_count++;
	}
	else if( match( $0, /<dd>(New member|Member|Moderator|Administrator|Developer)<\/dd>/, res ) ) {
		author_rank = res[ 1 ];
		submatch_count++;
	}
	else if( match( $0, /<dd><strong>GitHub:<\/strong> (.+)<\/dd>/, res ) ) {
		# old layout
		author_github_handle = res[ 1 ];
	}
	else if( match( $0, /title="Visit .+ Github page"><span>(.+)<\/span><\/a>/, res ) ) {
		# new layout
		author_github_handle = res[ 1 ];
	}
	else if( match( $0, /<dd><strong>In-game:<\/strong> (.+)<\/dd>/, res ) ) {
		author_player_handle = res[ 1 ];
	}
	else if( match( $0, /<dd><strong>Posts:<\/strong> ([0-9]+)<\/dd><dd><strong>Joined:<\/strong> (... ... .., .... ..?:..)<\/dd>/, res ) ) {
		# new layout
		author_post_total = res[ 1 ];
		author_join_date = convert_clock( res[ 2 ] );
		submatch_count++;
	}
	else if( match( $0, /<dd><strong>Posts:<\/strong> ([0-9]+)<\/dd><dd><strong>Joined:<\/strong> (... ... .., .... ..?:.. ..)<\/dd>/, res ) ) {
		# old layout
		author_post_total = res[ 1 ];
		author_join_date = res[ 2 ];
		submatch_count++;
	}
	else if( match( $0, /<p class="author">by <strong><a .+>(.+)<\/a><\/strong> &raquo; <a .+>(... ... .., .... ..?:..)<\/a><\/p>/, res ) ) {
		author_name = res[ 1 ];
		post_date = convert_clock( res[ 2 ] );
		submatch_count++;
	}
	else if( match( $0, /<p class="author"><img .+>by <strong>(.+)<\/strong> &raquo; (... ... .., .... ..?:.. ..) <\/p>/, res ) ) {
		# old layout
		author_name = res[ 1 ];
		gsub( /<[^>]+>/, "", author_name );
		post_date = res[ 2 ];
		submatch_count++;
	}
	else if( match( $0, /<h3.*><a href="#p([0-9]+)">(.*)<\/a><\/h3>/, res ) ) {
		post_id = res[ 1 ];
		post_title = res[ 2 ];
		post_count++;
		submatch_count++;
	}
	else if( match( $0, /<div class="content">(.+)<\/div>/, res ) ) {
		post_content = res[ 1 ];
		submatch_count++;
	}
	else if( $0 ~ /<div class="content">/ ) {	# slurp the multiline post
		text = $0;
		while( getline > 0 && $0 != "" ) {
			text = text "\n" $0;
		}
		if( match( text, /<div class="content">(.+)<\/div>/, res ) ) {
			post_content = res[ 1 ];
			submatch_count++;
		}
	}
	else if( $0 ~ /<hr class="divider" ?\/>/ ) {
		# sanity check: we expect correct number of results
		if( submatch_count != 5 && mode != "debug" ) {
			if( mode == "check" )
				abort( "Failed to parse " FILENAME " at line " NR );
			end
			abort( );
		}

		if( mode == "debug" ) {
			print( "[" submatch_count " of 5 submatches]" );
			print( "post_id=" post_id );
			print( "post_title=" post_title );
			print( "post_count=" post_count );
			print( "post_date=" post_date );
			print( "author_name=" author_name );
			print( "author_rank=" author_rank );
			print( "author_join_date=" author_join_date );
			print( "author_post_total=" author_post_total );
			print( "author_github_handle=" author_github_handle );
			print( "author_player_handle=" author_player_handle );
		}
		else if( mode == "compile" ) {
			print( author_name, get_page_path( ), post_id, post_date, post_count, topic_title );
		}
		else if( mode == "extract" ) {
			target_file = "posts/" post_id ".txt";

			if( page_count == 1 )
				printf( "@https://forums.minetest.net/viewtopic.php?f=%d&t=%d#p%d\n", forum_id, topic_id, post_id ) > target_file;
			else
				printf( "@https://forums.minetest.net/viewtopic.php?f=%d&t=%d&start=%d#p%d\n", forum_id, topic_id, ( page_count - 1 ) * 25, post_id ) > target_file;
			print( "Cache-Date:", cache_date ) > target_file;
			print( "Robot-Name:", robot_name ) > target_file;
			print( "Robot-URL:", robot_url ) > target_file;
			print( "Forum-ID:", forum_id ) > target_file;
			print( "Topic-ID:", topic_id ) > target_file;
			print( "Topic-Title:", topic_title ) > target_file;
			print( "Author-Name:", author_name ) > target_file;
			print( "Post-ID:", post_id ) > target_file;
			print( "Post-Date:", post_date ) > target_file;
			print( "Post-Title:", post_title ) > target_file;
			print( "\n" post_content ) > target_file;
		}
		else {
			body_output = body_output inject_local_vars( body );
		}
		submatch_count = 0;
		post_id = "";
		post_date = "";
		post_title = "";
		author_name = "";
		author_rank = "";
		author_post_total = "";
		author_join_date = "";
		author_player_handle = "";
		author_github_handle = "";
	}
	else if( !post_total && $0 ~ /<div class="pagination">/ ) {
		if( !getline || !match( strip_highlights( ), /([0-9]+) posts?/, res ) ) {
			next;
		}
		post_total = res[ 1 ];

		if( !getline || !match( strip_highlights( ), /Page <strong>([0-9]+)<\/strong> of <strong>([0-9]+)<\/strong>/, res ) ) {
			next;
		}
		page_count = res[ 1 ];
		page_total = res[ 2 ];

		match_count++;
	}
}

END {
	if( status ) exit;

	if( mode == "check" && match_count != 4 ) {
		abort( "Failed to parse " FILENAME );
	}
	else if( mode == "debug" ) {
		print( "[" match_count " of 4 matches]" );
		print( "robot_name=" robot_name );
		print( "robot_url=" robot_url );
		print( "cache_date=" cache_date );
		print( "forum_id=" forum_id );
		print( "forum_title=" forum_title );
		print( "topic_id=" topic_id );
		print( "topic_title=" topic_title );
		print( "page_total=" page_total );
		print( "page_count=" page_count );
		print( "post_total=" post_total );
	}
	else if( mode == "parse" && match_count == 4 ) {
		target_file = get_target_file( "pages/" );

		while( ( getline < "templates/header.htm" ) > 0 ) {
			inject_global_vars( );
			header = header $0 "\n";
		}
		while( ( getline < "templates/footer.htm" ) > 0 ) {
			inject_global_vars( );
			footer = footer $0 "\n";
		}

		print header > target_file;
		print body_output > target_file;
		print footer > target_file;

#		print header body_output footer;
	}
}
