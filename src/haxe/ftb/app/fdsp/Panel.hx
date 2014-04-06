package ftb.app.fdsp;

import haxe.ds.StringMap;

import js.html.HtmlElement;
import js.html.DivElement;
import js.html.MouseEvent;
import js.html.Event;
import js.Browser;
import js.Lib;

/**
 * ...
 * @author filt3rek
 */

private enum PanelAction {
	move( panel : Panel );
	resize( panel : Panel );
}

@:expose
class Panel {
	
	// helpers to get and element correct size (inluding paddings, borders...) 
	static var _horMargins			= [ "paddingLeft", "paddingRight", "borderLeftWidth", "borderRightWidth" ];
	static var _verMargins			= [ "paddingTop", "paddingBottom", "borderTopWidth", "borderBottomWidth" ];
	static var _rNbr				= ~/[0-9]+/;
	
	static var _panelAction			: PanelAction;
	static var _globalBinds			: StringMap<Event->Void> ;	// JS bind functions (to use correctly with JS event handling...)
	
	public var title	(default, set)	: String;
	
	var _binds	: StringMap<Event->Void>;							// JS bind functions (to use correctly with JS event handling...)
	
	/*
	 *        containerDiv :
	 *  _________________________
	 * |___________hat___________|
	 * |                         |
	 * |                         |
	 * |          inDiv          |
	 * |                     ____|
	 * |____________________|_br_|
	 * 
	 */
	
	var _containerDiv		: DivElement;
	var _inDiv				: DivElement;
	var _hat				: DivElement;
	var _br					: DivElement;
	
	// helpers for correct move and resize
	var _inDivStartWidth	: Int;
	var _inDivStartHeight	: Int;
	var _startX				: Int; 
	var _startY				: Int; 
	var _hatDivStartWdith	: Int; 
	var _hatMargins			: { margX : Int, margY : Int };
	
	static function __init__() {
		_globalBinds = new StringMap();
		_globalBinds.set( "cb_mouseUp", cb_mouseUp );
		untyped Browser.document.attachEvent( "onmouseup", _globalBinds.get( "cb_mouseUp" ) );
	}
	
	// global mouse up listener handler (get the panel action stopped even if outside the sensor...)
	static  function cb_mouseUp( e : Event ) {
		var panel	= null;
		if ( _panelAction != null )
		{
			switch( _panelAction ) {
				case move( p )	:
					panel = p;
					untyped Browser.document.detachEvent( "onmousemove", p._binds.get( "cb_movePanel" ) );
					
				case resize( p )	:
					panel = p;
					untyped Browser.document.detachEvent( "onmousemove", p._binds.get( "cb_resizePanel" ) );
			}
			_panelAction = null;
		}
		if ( panel != null )
		{
			var margs	= getMargins( cast panel._inDiv );
			FDSP.savePanelProperties( panel._inDiv.id , { x : panel._containerDiv.offsetLeft, y : panel._containerDiv.offsetTop, width : panel._inDiv.offsetWidth - margs.margX, height : panel._inDiv.offsetHeight - margs.margY, zIndex : untyped panel._containerDiv.currentStyle.zIndex } );
		}
	}
	
	// helper to get and element correct size (inluding paddings, borders...) 
	static function getMargins( el : HtmlElement ) {
		var margX	= 0;
		var margY	= 0;
		for ( i in _horMargins ) {
			try{
				_rNbr.match( cast( Reflect.field( untyped el.currentStyle, i ), String ) );
				margX += Std.parseInt( _rNbr.matched( 0 ) );
			}catch( e : Dynamic ){}
		}
		for ( i in _verMargins ) {
			try{
				_rNbr.match( cast( Reflect.field( untyped el.currentStyle, i ), String ) );
				margY += Std.parseInt( _rNbr.matched( 0 ) );
			}catch( e : Dynamic ){}
		}
		return { margX : margX, margY : margY };
	}
	
	public function new( title : String, inDivId : String ) {
		_binds	= new StringMap();
		_binds.set( "bringToFront", bringToFront );
		_binds.set( "cb_hatPressed", cast cb_hatPressed );
		_binds.set( "cb_BRPressed", cast cb_BRPressed );
		_binds.set( "cb_movePanel", cast cb_movePanel );
		_binds.set( "cb_resizePanel", cast cb_resizePanel );
		
		// container setttings
		_containerDiv					= cast Browser.document.createElement( "div" );
		_containerDiv.style.position	= "absolute";
		untyped _containerDiv.attachEvent( "onmousedown", _binds.get( "bringToFront" ) );
		
		// user DIV settings
		_inDiv					= cast Browser.document.getElementById( inDivId );
		_inDiv.style.margin		= "0px";
		_inDiv.style.visibility	= "hidden";
		
		// hat settings	
		_hat						= cast Browser.document.createElement( "div" );
		_hat.className				= "panel_hat";
		_hat.style.cursor			= "move";
		_hat.style.overflow			= "hidden";
				
		// bottom right btn
		_br								= cast Browser.document.createElement( "div" );
		_br.style.position				= "absolute";
		_br.style.backgroundImage		= "url( 'gfx/resize.gif' )";
		_br.style.cursor				= "nw-resize";
		_br.style.width					= "10px";
		_br.style.height				= "10px";
		
		// layout
		Browser.document.body.insertBefore( _containerDiv, _inDiv );
		Browser.document.body.removeChild( _inDiv );
		for ( i in [ _hat, _inDiv, _br ] ) {
			_containerDiv.appendChild( i );
		}
		
		_hatMargins		= getMargins( cast _hat );
		this.title		= title;
		
		// move panel
		untyped _hat.attachEvent( "onmousedown", _binds.get( "cb_hatPressed" ) );
		
		// resize panel
		untyped _br.attachEvent( "onmousedown", _binds.get( "cb_BRPressed" ) );
		
		if ( FDSP.panelProperties != null )
			cb_onClientReady();
		else
			FDSP.onReady.add( cb_onClientReady );
	}
	
	public function destroy() {
		untyped _containerDiv.detachEvent( "onmousedown", _binds.get( "bringToFront" ) );
		untyped _hat.detachEvent( "onmousedown", _binds.get( "cb_hatPressed" ) );
		untyped _br.detachEvent( "onmousedown", _binds.get( "cb_BRPressed" ) );
		untyped Browser.document.detachEvent( "onmouseup", _globalBinds.get( "cb_mouseUp" ) );
	}
	
	public function bringToFront(_) {
		FDSP.bringDivToFront( _containerDiv );
	}
	
	function set_title( s : String ) {
		title = s;
		if ( _hat != null )
		{
			if ( _hat.firstChild != null )
				_hat.removeChild( _hat.firstChild );
			_hat.appendChild( Browser.document.createTextNode( s ) );
		}
		return s;
	}
	
	// real initialization (when FDSP onReady fired)
	function cb_onClientReady() {
		if ( FDSP.panelProperties.exists( _inDiv.id ) )
		{
			var props 					=  FDSP.panelProperties.get( _inDiv.id );
			_inDiv.style.width			= props.width + "px";
			_inDiv.style.height			= props.height + "px";
			_containerDiv.style.left	= props.x + "px";
			_containerDiv.style.top		= props.y + "px";
			_containerDiv.style.zIndex	= '' + props.zIndex;
		}
		
		_hat.style.width		= _inDiv.offsetWidth - _hatMargins.margX + "px";
		
		_br.style.left			= _inDiv.offsetWidth - _br.offsetWidth -1 + "px";
		_br.style.top			= _hat.offsetHeight + _inDiv.offsetHeight - _br.offsetWidth - 1 + "px";
		
		_inDiv.style.visibility	= "visible";
	}
	
	function cb_hatPressed( e : MouseEvent ) {
		var target		= untyped e.srcElement;
		_panelAction	= move( this );
		
		var x 			= e.clientX + untyped js.Browser.document.documentElement.scrollLeft;
		var y 			= e.clientY + untyped js.Browser.document.documentElement.scrollTop;
		_startX 		= x - _containerDiv.offsetLeft;
		_startY 		= y - _containerDiv.offsetTop;
		
		untyped Browser.document.attachEvent( "onmousemove", _binds.get( "cb_movePanel" ) );
	}
	
	function cb_BRPressed( e : MouseEvent ) {
		var target		= untyped e.srcElement;
		_panelAction	= resize( this );
		
		var x 			= e.clientX + untyped js.Browser.document.documentElement.scrollLeft;
		var y			= e.clientY + untyped js.Browser.document.documentElement.scrollTop;
		_startX 		= x;
		_startY 		= y;
				
		// hat
		_hatDivStartWdith	= _hat.offsetWidth - getMargins( cast _hat ).margX;
		
		// inDiv
		var margs			= getMargins( cast _inDiv );
		_inDivStartWidth 	= _inDiv.offsetWidth - margs.margX;
		_inDivStartHeight 	= _inDiv.offsetHeight - margs.margY;
		
		untyped Browser.document.attachEvent( "onmousemove", _binds.get( "cb_resizePanel" ) );
	}
	
	function cb_movePanel( e : MouseEvent ) {
		var x = e.clientX + untyped js.Browser.document.documentElement.scrollLeft - _startX;
		var y = e.clientY + untyped js.Browser.document.documentElement.scrollTop - _startY;
		
		_containerDiv.style.left	= x + "px";
		_containerDiv.style.top		= y + "px";
	}
	
	function cb_resizePanel( e : MouseEvent ) {
		var x = e.clientX + untyped js.Browser.document.documentElement.scrollLeft - _startX;
		var y = e.clientY + untyped js.Browser.document.documentElement.scrollTop - _startY;
		
		// minimum size
		if ( _inDivStartWidth + x < 100 || _inDivStartHeight + y < _hat.offsetHeight )
			return;
		
		_inDiv.style.width	= _inDivStartWidth + x + "px";
		_inDiv.style.height	= _inDivStartHeight + y + "px";
		
		_hat.style.width		= _inDiv.offsetWidth - _hatMargins.margX + "px";
		
		_br.style.left			= _inDiv.offsetWidth - _br.offsetWidth - 1 + "px";
		_br.style.top			= _hat.offsetHeight + _inDiv.offsetHeight - _br.offsetWidth - 1 + "px";			
	}
}