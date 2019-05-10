#!/bin/awk -f

#######################################
#                                     #
#  Minetest Forum Recovery Project    #
#  by sorcerykid                      #
#                                     #
#######################################

# Generates a formatted HTML listing of topics from a tab-delimited digest
#
# Example usage:
#   % ./publish_topics.awk -v forum_id=3 digest.txt > /var/www/html/forums/general_discussion.html

function abort( msg ) {
	status = 1;
	if( msg ) print( msg );
	exit;
}

BEGIN {
	FS = "\t";
	forums[ 18 ] = "News";
	forums[ 42 ] = "Builds";
	forums[ 3 ] = "General Discussion";
	forums[ 5 ] = "Feature Discussion";
	forums[ 6 ] = "Problems";
	forums[ 10 ] = "Servers";
	forums[ 11 ] = "Mod Releases";
	forums[ 9 ] = "WIP Mods";
	forums[ 47 ] = "Modding Discussion";
	forums[ 15 ] = "Game Releases";
	forums[ 49 ] = "Game Discussion";
	forums[ 50 ] = "WIP Games";
	forums[ 14 ] = "Minetest-related projects";
	forums[ 4 ] = "Texture Packs";
	forums[ 12 ] = "Maps";

	if( !forums[ forum_id ] ) {
		abort( "Unknown forum id" );
	}

        print( "<HTML>" );
        print( "<HEAD>" );
        print( "<TITLE>Minetest Forum Recovery Project</TITLE>" );
        print( "<STYLE>TH, TD, P, H1 { font-family: arial, helvetica; } TD, P { font-size: 14px; } TH { font-size: 16px; } H1 { font-size: 32px; } BIG { font-size: 24px; }</STYLE>" );
        print( "</HEAD>" );

        print( "<BODY><CENTER><DIV STYLE=\"width: 800px;\">" );
        print( "<H1 STYLE=\"margin-top: 0px;\"><IMG SRC=\"minetest-logo.png\" VSPACE=\"8\"><BR>Minetest Forum Recovery Project</H1>" );
        print( "<P>The following pages were compiled and collated from a variety of search engine caches.</P><P>The <IMG SRC=\"new_icon.png\"> icon identifies topics that were started between March 13 and April 28.</P><P>All links will remain permanent and can be safely referenced within new forum discussions.</P>" );
        print( "<TABLE STYLE=\"border-style: solid; border-color: lightgrey; border-width: 2px;\" WIDTH=\"800\" CELLPADDING=\"6\" CELLSPACING=\"0\">" );
	print( "<TR><TH COLSPAN=\"3\"><BIG>" forums[ forum_id ] "</BIG></TH></TR>" );
        print( "<TR BGCOLOR=\"lightgrey\"><TH WIDTH=\"70%\" ALIGN=\"left\">Topic Title</TH><TH WIDTH=\"20%\" ALIGN=\"left\">Pages</A></TH><TH WIDTH=\"10%\" ALIGN=\"left\">Posts</A></TH>" );
}

{
	match( $2, /^pages\/([0-9]+)_([0-9]+)\.htm$/, res ) || match( $2, /^pages\/([0-9]+)_([0-9]+)_([0-9]+)\.htm$/, res );

	topic_id = res[ 2 ];
	topic_title = $6;
	post_date = $4;
	page_count = res[ 3 ] ? res[ 3 ] / 25 + 1 : 1;
	post_count = $5;

	if( res[ 1 ] == forum_id ) {
		topics[ topic_id, "title" ] = topic_title;

		if( match( post_date, /^... (...) (..), 2019/, res ) && ( res[ 1 ] == "Apr" || res[ 1 ] == "Mar" && res[ 2 ] > 12 ) ) {
			topics[ topic_id, "pages", page_count ]++;
			if( post_count == 1 && page_count == 1 ) {
				topics[ topic_id, "is_new" ] = 1;
			}
			post_totals[ topic_id ]++;
		}
	}
}

END {
	if( status ) exit;

	for( topic_id in post_totals ) {
		topic_title = topics[ topic_id, "title" ];
		total_posts += post_totals[ topic_id ];
		total_topics++;

		len_pages = 1;
		for( i in topics ) {
			split( i, idx, SUBSEP );
			if( idx[ 1 ] == topic_id && idx[ 2 ] == "pages" ) {
				pages[ len_pages++ ] = idx[ 3 ];
				total_pages++;
			}
		}
		printf( "<TR><TD>%s</TD><TD>", topics[ topic_id, "is_new" ] ? topic_title " <IMG SRC=\"new_icon.png\">" : topic_title );
		asort( pages );
		for( i in pages ) {
			if( pages[ i ] > 1 )
				printf( "[ <A HREF=\"pages/%d_%d_%d.htm\">%d</A> ]", forum_id, topic_id, ( pages[ i ] - 1 ) * 25, pages[ i ] );
			else
				printf( "[ <A HREF=\"pages/%d_%d.htm\">%d</A> ]", forum_id, topic_id, 1 );
		}
		printf( "</TD><TD>%d</TD></TR>\n", post_totals[ topic_id ] );

		delete pages;
	}

        print( "</TABLE>" );
        printf( "<P>Recovered %d posts, %d pages, and %d topics between March 13, 2019 and April 28, 2019</P>", total_posts, total_pages, total_topics );
        printf( "<P>Results generated on %s</P>", strftime( ) );
        print( "</DIV></CENTER></BODY>" );
        print( "</HTML>" );
}
