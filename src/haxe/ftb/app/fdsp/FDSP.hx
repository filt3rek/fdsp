package ftb.app.fdsp;

/**
 * ...
 * @author filt3rek
 */

import ftb.app.fdsp.Types;

import haxe.ds.StringMap;

#if js

import haxe.remoting.HttpAsyncConnection;

import js.Lib;
import js.Browser;
import js.html.MouseEvent;
import js.html.DivElement;
import js.html.Event;

import ftb.app.fdsp.Panel;

@:expose
class FDSP {
	
	public static var onReady			(default, null)	= new List();			// fired when the panels properties are loaded
	public static var panelProperties	(default, null)	: StringMap<PanelProperty>;
	
	static var _globalBinds	: StringMap<Event->Void> ;							// JS bind functions (to use correctly with JS event handling...)
	static var _hxr			: HttpAsyncConnection;								// haxe remoting
	static var _tooltipDiv	: DivElement; 
	
	static function __init__() {
		_globalBinds	= new StringMap();
		_globalBinds.set( "cb_moveTooltip", cast cb_moveTooltip );
	}
		
	public static function init( tooltipDivID : String ) {
		_tooltipDiv	= cast Browser.document.getElementById( tooltipDivID );
		_tooltipDiv.style.position	= "absolute";
		_tooltipDiv.style.display	= "none";
		
		_hxr	= HttpAsyncConnection.urlConnect( "http://127.0.0.1:2010" );
		_hxr.setErrorHandler( Lib.alert );
		loadPanelsProperties();
	}
	
	static function loadPanelsProperties() {
		function cb_propertiesLoaded( h : StringMap<PanelProperty> ) {
			panelProperties = h;
			for ( f in onReady )
				f();
		}
		_hxr.externalNeko.loadPanelsProperties.call( [], cb_propertiesLoaded );
	}
	
	public static function savePanelProperties( id : String, pp : PanelProperty ) {
		_hxr.externalNeko.savePanelProperties.call( [ id, pp ] );
	}
	
	// helpers
	public static function bringDivToFront( el : DivElement ) {
		var max 	= 0;
		var elts	= Browser.document.getElementsByTagName( "DIV" );
		for ( i in 0...elts.length ) {
			max = cast Math.max( max, untyped elts[ i ].currentStyle.zIndex );
		}
		el.style.zIndex = '' + max + 1;
	}
	
	public static function cb_showTooltip( e : MouseEvent, text : String )	{
		bringDivToFront( _tooltipDiv );
		_tooltipDiv.innerHTML 		= text;
		_tooltipDiv.style.display	= "block";
		
		cb_moveTooltip( e );
		
		var target = untyped e.srcElement;
		untyped target.attachEvent( "onmousemove", _globalBinds.get( "cb_moveTooltip" ) );
	}
	
	public static function cb_hideTooltip( e : Event ) {
		_tooltipDiv.style.display	= "none";
		
		var target = untyped e.srcElement;
		untyped target.detachEvent( "onmousemove", _globalBinds.get( "cb_moveTooltip" ) );
	}
	
	static function cb_moveTooltip( e : MouseEvent ) {
		var x = e.clientX + untyped js.Browser.document.documentElement.scrollLeft;
		var y = e.clientY + untyped js.Browser.document.documentElement.scrollTop;
		
		_tooltipDiv.style.left	= x + 10 + "px";
		_tooltipDiv.style.top	= y - _tooltipDiv.offsetHeight - 10 + "px";
	}
}

#elseif neko

import haxe.remoting.Context;
import haxe.remoting.HttpConnection;
import haxe.Serializer;
import haxe.Unserializer;

import sys.FileSystem;
import sys.io.File;

import neko.vm.Loader;
import neko.vm.Module;
import neko.Lib;

using StringTools;

class FDSP {
	
	public static var plugins	(default, null) = new StringMap<Module>();
	
	static function main() {
		
		var socket = new sys.net.Socket();
		socket.bind( new sys.net.Host( "127.0.0.1" ), 2010 );
		socket.listen( 10 );
				
		while ( true ) {
			var cnx		= socket.accept();
			var headers	= new StringMap();
			var buf		= "";
			while ( true ) {
				var c	= 0;
				try {
					c	= cnx.input.readByte();
				}
				catch ( e : Dynamic ) {
					trace( e );
					break;
				}
				// reading the HTTP request, splitting headers and body content
				var pos	= buf.indexOf( "\r\n\r\n" );
				if ( pos != -1 ) {
					var a	=	buf.substr( 0, pos ).split( "\r\n" );
					for ( i in a ) {
						var split	= i.split( ":" );
						var key		= split.shift().trim().toLowerCase();
						headers.set( key, split.join( ":" ).trim() );
					}
					buf	= buf.substr( pos + 4 );
					buf += String.fromCharCode( c ) + cnx.input.readString( Std.parseInt( headers.get( "content-length" ) ) - buf.length - 1 );
					
					// external context available for the browser
					var ctx = new Context();
					ctx.addObject( "externalNeko", FDSP, true );
					
					// sending back the response
					var command = buf.split( "__x=" )[ 1 ];
					cnx.output.writeString( HttpConnection.processRequest( command.urlDecode(), ctx ) );
					cnx.output.flush();
					cnx.close();
					buf	= "";
					break;
				}
				buf += String.fromCharCode( c );
			}
		}
	}
	
	// the hole :D
	public static function plugin( s : String, f : String, args : Array<Dynamic> ) {
		if ( !plugins.exists( s ) )
			plugins.set( s, Loader.local().loadModule( s ) );
			
		var module				= plugins.get( s );

		var classes : Dynamic	= module.exportsTable().__classes;
		var path 				= f.split( "." );
		var f					= path.pop();
		var o	= classes;
		for ( i in path ) {
			o = Reflect.field( o, i );
		}
		return Reflect.callMethod( o, Reflect.field( o, f ), args );
	}
	
	// save and load the panels properties as width, height, position...
	public static function savePanelProperties( id : String, pp : PanelProperty ) {
		var h = loadPanelsProperties();
		h.set( id, pp );
		File.saveContent( "fdsp.dat", Serializer.run( h ) );
	}
	
	public static function loadPanelsProperties() : StringMap<PanelProperty> {
		return try{
			Unserializer.run( File.getContent( "fdsp.dat" ) );
		}catch ( e : Dynamic ) { new StringMap(); }
	}
}
#end