package ftb.app.fdsp.plugin.fdallproj;

/**
 * ...
 * @author filt3rek
 * 
 * FD ALl Projects "plugin"
 * 
 */

import ftb.app.fdsp.plugin.fdallproj.Types;

 #if js

import haxe.ds.StringMap;
import haxe.remoting.HttpAsyncConnection;

import js.Lib;
import js.Browser;
import js.html.HtmlElement;
import js.html.UListElement;
import js.html.AnchorElement;
import js.html.DivElement;
import js.html.Event;

#if jsmodule
import FDSP;
#else
import ftb.app.fdsp.Panel;
import ftb.app.fdsp.FDSP;
#end

using StringTools;
using Std;

@:expose class FDAllProj {
	
	static var _globalBinds	: StringMap<Dynamic>;	// JS bind functions (to use correctly with JS event handling...)
	static var _descriptions: StringMap<String>;		// handles the projects descriptions...(really ? :D)
	static var _inDiv		: DivElement;
	static var _panel		: Panel;
	
	static function __init__() {
		_globalBinds = new StringMap();
		_globalBinds.set( "showTooltip", showTooltip );
		//_globalBinds.set( "hideTooltip", FDSP.cb_hideTooltip );
	}
	
	public static function init( inDivId : String ) {
		_inDiv	= cast Browser.document.getElementById( inDivId );
		_panel	= new Panel( "All FD Projects", inDivId );
		
		// global DIV listener for all anchors (tooltip)
		untyped _inDiv.attachEvent( "onmouseover", _globalBinds.get( "showTooltip" ) );
		untyped _inDiv.attachEvent( "onmouseout", _globalBinds.get( "hideTooltip" ) );
	}
	
	public static function destroy() {
		untyped _inDiv.detachEvent( "onmouseover", _globalBinds.get( "showTooltip" ) );
		untyped _inDiv.detachEvent( "onmouseout", _globalBinds.get( "hideTooltip" ) );
	}
	
	static function showTooltip( e : Event ) {
		var target = untyped e.srcElement;
		if ( target.nodeName == "A" ) untyped
		{
			var name = target.name;
			FDSP.cb_showTooltip( e, _descriptions.get( name ) );
		}
	}
	
	// hxr method (haxe remoting)
	public static function showFDProjects( root : String ) {
		var hxr		= HttpAsyncConnection.urlConnect( "http://127.0.0.1:2010" );
		
		hxr.setErrorHandler( function( e ) {
			if ( e == "std@sys_file_type" )
			{
				if( _inDiv.firstChild != null )
					_inDiv.removeChild( _inDiv.firstChild );
					
				_inDiv.appendChild( Browser.document.createTextNode( "Path not found : " + root ) );
			}
			else
				Lib.alert( e );
		});
		hxr.externalNeko.plugin.call( [ "fdallproj", "ftb.app.fdsp.plugin.fdallproj.src.FDAllProj.getFDProjects", [ root ] ], cb_response );
		if( _inDiv.firstChild != null )
			_inDiv.removeChild( _inDiv.firstChild );
		_inDiv.appendChild( Browser.document.createTextNode( "Loading..." ) );
	}
	
	// server response
	static function cb_response( projects : Array<ProjectInfo> ) {
		_panel.title 	= "All FD Projects ( " + projects.length + " projects found )";
		
		var ulr 			: UListElement	= cast Browser.document.createElement( "ul" );
		ulr.style.margin					= "0px";
		ulr.style.padding					= "0px";
		
		if( _inDiv.firstChild != null )
			_inDiv.removeChild( _inDiv.firstChild );
		_inDiv.appendChild( ulr );
		
		_descriptions	= new StringMap();
		
		// creating the tree view
		for ( o in projects ) {
			var p						= o.path;
			var target					= o.target;
			var path					= p.split( "/" );
			var a		: AnchorElement	= cast Browser.document.createElement( "a" );
			a.name						= p;
			untyped a.alt				= "test";
			a.href 						= 'javascript:window.external.OpenProject( "$p" )';
			var desc					=
'<div style="float:left;width:50px;font-weight:bold;">Source</div>:&nbsp;${o.src}<br />
<div style="float:left;width:50px;font-weight:bold;">Target</div>:&nbsp;${o.target}&nbsp;${o.v}<br />
<div style="float:left;width:50px;font-weight:bold;">Path</div>:&nbsp;${ o.path }';

			_descriptions.set( p, desc );
			var ul					= ulr;
			for ( s in path ) {
				var child	= null;
				for ( j in 0...ul.childNodes.length ) {
					if ( s == ul.childNodes[ j ].firstChild.nodeValue ){
						child	= ul.childNodes[ j ].firstChild.nextSibling;
						break;
					}
				}
				if ( child != null )
					ul	= cast child;
				else
				{
					var ul2			= Browser.document.createElement( "ul" );
					ul2.className	= "tree";
					var li2 		= Browser.document.createElement( "li" );
					li2.className	= "tree";
					if ( s.endsWith( ".hxproj" ) )
					{
						var text	= Browser.document.createTextNode( s.substr( 0, -7 ) );
						a.appendChild( text );
						li2.appendChild( a );
					}
					else
						li2.appendChild( Browser.document.createTextNode( s ) );
					li2.appendChild( ul2 );
					ul.appendChild( li2 );
					ul	= cast ul2;
				}
			}
		}
		
		function rec( el : HtmlElement ) {
			for ( i in 0...el.childNodes.length ) {
				var child : HtmlElement = cast el.childNodes[ i ];
				if ( child.nodeName == "LI" && child == el.lastChild )
					child.className += " last";
				
				if ( child.childNodes.length > 0 )
					rec( child );
			}
		}
		
		rec( cast ulr );
	}
}

#elseif neko

import haxe.xml.Fast;

import sys.FileSystem;
import sys.io.File;

using StringTools;
using Std;

class FDAllProj {
	
	static var _projects	: Array<ProjectInfo>;
	
	// process the recursive FD projects search 
	public static function getFDProjects( root : String ) {
		_projects	= [];
		// normalize the path
		root	= root.replace( "\\", "/" );
		if ( root.endsWith( "/" ) )
			root = root.substr( 0, -1 );

		processPath( root );
		return _projects;
	}
	
	static function processPath( path : String ) {
		if ( FileSystem.isDirectory( path ) )
		{
			for ( subPath in FileSystem.readDirectory( path ) ) {
				if ( FileSystem.isDirectory( path + "/" + subPath ) )
					processPath( path + "/" + subPath );	
				else
					processFile( path + "/" + subPath );
			}
		}
		else
			processFile( path );
	}
	
	static function processFile( path : String ) {
		if ( path.endsWith( ".hxproj" ) ) {
			
			// getting some project infos from the .hxproj file
			var fast	= new Fast( Xml.parse( File.getContent( path ) ).firstElement() );
			var target	= null;
			var maj		= 0;
			var min		= null;
			var src		= null;
			
			// little mess becasue of different FD project versions...
			try{
				for ( out in fast.node.output.elements ) {
					
						if ( out.has.platform )
							target = out.att.platform;
						if ( out.has.version )
							maj = Std.parseInt( out.att.version );
						if ( out.has.minorVersion )
							min = out.att.minorVersion;
					
				}
			}catch( e : Dynamic ) {}
						
			if ( target == null )
			{
				switch( maj ) {
					case 6, 7, 8, 9, 10	:
						src		= "AS";
						target	= "Flash Player";
					case 11	:
						src		= "Haxe";
						target	= "JavaScript";
					case 12	:
						src		= "Haxe";
						target	= "Neko";
					case 13	:
						src		= "Haxe";
						target	= "PHP";
				}
			}
			
			try {
				var ext = fast.node.compileTargets.node.compile.att.path;
				src = if ( ext.endsWith( ".as" ) )
						"AS";
					else
						if ( ext.endsWith( ".hx" ) )
							"Haxe";
						else
							if ( ext.endsWith( ".nmml" ) )
								"NME";
							else
								null;
			}catch ( e : Dynamic ) { }
			
			if ( src == null )
				src = target == "Flash Player" ? "AS" : "Haxe";
			
			if ( src == "AS" )
				src += ( ( maj < 9 ) ? "2" : "3" );
				
			var v = maj + ( min != null ? "." + min : "" );
			
			_projects.push( { target : target, src : src, v : v, path : path } );
		}
	}
}

#end