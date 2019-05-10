#!/bin/awk -f

#######################################
#                                     #
#  Minetest Forum Recovery Project    #
#  by sorcerykid                      #
#                                     #
#######################################

# Generates a formatted HTML listing of posts from a tab-delimited digest
#
# Example usage:
#   % sort digest.txt | ./publish_posts.awk > /var/www/html/forums/digest.html

BEGIN {
	FS ="\t";	

	print( "<HTML>" );
	print( "<HEAD>" );
	print( "<TITLE>Minetest Forum Recovery Project</TITLE>" );
	print( "<STYLE>TH, TD, P, H1 { font-family: arial, helvetica; } TD, P { font-size: 14px; } TH { font-size: 16px; } H1 { font-size: 32px; }</STYLE>" );
	print( "</HEAD>" );

	print( "<BODY><CENTER><DIV STYLE=\"width: 850px;\">" );
	print( "<H1 STYLE=\"margin-top: 0px;\"><IMG SRC=\"minetest-logo.png\" VSPACE=\"8\"><BR>Minetest Forum Recovery Project</H1>" );
	print( "<P>The following posts were compiled and collated from a variety of search engine caches.</P><P>The <IMG SRC=\"new_icon.png\"> icon identifies topics that were started between March 13 and April 28.</P><P>All links will remain permanent and can be safely referenced within new forum discussions.</P>" );
	print( "<TABLE STYLE=\"border-style: solid; border-color: lightgrey; border-width: 2px;\" WIDTH=\"850\" CELLPADDING=\"6\" CELLSPACING=\"0\">" );
	print( "<TR><TH COLSPAN=\"3\"><BIG>Post History</BIG></TH></TR>" );
	print( "<TR BGCOLOR=\"lightgrey\"><TH ALIGN=\"left\">Member Name</TH><TH ALIGN=\"left\">Post Date</A></TH><TH ALIGN=\"left\">Topic Title</TH>" );
}

{
	is_first_post = ( $5 == 1 && $2 ~ /^pages\/[0-9]+_[0-9]+\.htm$/ );

	if( match( $4, /^... (...) (..), 2019/, res ) && ( res[ 1 ] == "Apr" || res[ 1 ] == "Mar" && res[ 2 ] > 12 ) ) {
		printf( "<TR><TD>%s</TD><TD><A HREF=\"%s#p%d\" TARGET=\"_blank\">%s</A></TD><TD>%s</TD></TR>\n", $1, $2, $3, $4, is_first_post ? $6 " <IMG SRC=\"new_icon.png\"></SMALL>" : $6 );
		posts_total++;
	}
}

END {
	print( "</TABLE>" );
	printf( "<P>Found %s recovered posts between March 13, 2019 and April 28, 2019</P>", posts_total );
	printf( "<P>Results generated on %s</P>", strftime( ) );
	print( "</DIV></CENTER></BODY>" );
	print( "</HTML>" );
}
