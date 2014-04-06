package;

import haxe.ds.StringMap;

import js.html.Event;
import js.html.DivElement;

/**
* ...
@author filt3rek
*/

@:native( "window.ftb.app.fdsp.FDSP" )
@:remove
extern class FDSP {
	public static var onReady : List<Void->Void>;
	public static var panelProperties : StringMap<PanelProperty>;
	public static function init( tooltipDivID : String ) : Void;
	public static function savePanelProperties( id : String, pp : PanelProperty ) : Void;
	public static function bringDivToFront( el : DivElement ) : Void;
	public static function cb_showTooltip( e : Event, text : String ) : Void;
	public static function cb_hideTooltip( e : Event ) : Void;
}

@:native( "window.ftb.app.fdsp.Panel" )
@:remove
extern class Panel {
	public var title (default,set)	: String;
	public function new ( title : String, inDivId : String ) : Void;
	public function destroy() : Void;
	public function bringToFront() : Void;
}

extern typedef PanelProperty = {
	x		: Int,
	y		: Int,
	width	: Int,
	height	: Int,
	zIndex	: Int
}