package ftb.app.fdsp.plugin.fdallproj;

/**
 * ...
 * @author filt3rek
 */

// Project Info from Neko
typedef ProjectInfo = {
	target 	: String,	// plateform (FlashPlayer, Neko, Javascript, AIR, NME...
	src 	: String,	// .hx or .as
	v 		: String,	// version (depending on plateform and FD project version...)
	path 	: String
}