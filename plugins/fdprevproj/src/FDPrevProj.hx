package com.filt3rek.fdsp.plugins.fdprevproj.src;

import haxe.xml.Fast;

import js.Lib;
import js.Dom;

import com.filt3rek.fdsp.plugins.fdprevproj.src.Types;
#if jsmodule
	import com.filt3rek.fdsp.external.FDSP;
#else
	import com.filt3rek.fdsp.src.Panel;
	import com.filt3rek.fdsp.src.FDSP;
#end

using Std;
using StringTools;

/**
 * ...
 * @author filt3rek
 * 
 * FD Previous Projects "plugin"
 * 
 */

@:expose class FDPrevProj {

	static var _globalBinds	: Hash<Dynamic>;			// JS bind functions (to use correctly with JS event handling...)
	static var _descriptions: Hash<String>;				// I don't know what to say..I hate writing comments for things that speak for themselves...:D
	static var _inDiv		: HtmlDom;
	static var _projects	: Array<RecentProjectInfo>;
	static var _initialized	= false;					// special init check var (FlashDevelop callback)
	
	static function __init__() {
		untyped __js__( "handleXmlData = com.filt3rek.fdsp.plugins.fdprevproj.src.FDPrevProj.handleXmlData" );
	}
	
	public static function init( inDivId : String ) {
		_globalBinds = new Hash();
		_globalBinds.set( "showTooltip", showTooltip );
		_globalBinds.set( "hideTooltip", FDSP.cb_hideTooltip );
				
		_inDiv			= Lib.document.getElementById( inDivId );
		var panel		= new Panel( "Recent Projects", inDivId );
		
		untyped _inDiv.attachEvent( "onmouseover", _globalBinds.get( "showTooltip" ) );
		untyped _inDiv.attachEvent( "onmouseout", _globalBinds.get( "hideTooltip" ) );
		
		_initialized	= true;
		refresh();
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

	static function refresh() {
		var ulr 			= Lib.document.createElement( "ul" );
		ulr.style.margin	= "0px";
		ulr.style.padding	= "0px";
		
		if( _inDiv.firstChild != null )
			_inDiv.removeChild( _inDiv.firstChild );
		_inDiv.appendChild( ulr );
		
		_descriptions	= new Hash();
		
		// creating the tree view
		for ( o in _projects ) {
			var p					= o.path;
			var path				= p.split( "/" );
			var a		: Anchor	= cast Lib.document.createElement( "a" );
			a.className				= "tree";
			a.name					= p;
			a.href 					= "javascript:window.external.OpenProject( '$p' )".format();
			var desc				=
'<div style="float:left;width:50px;font-weight:bold;">Created</div>:&nbsp;${o.created}<br />
<div style="float:left;width:50px;font-weight:bold;">Modified</div>:&nbsp;${o.modified}<br />
<div style="float:left;width:50px;font-weight:bold;">Path</div>:&nbsp;${o.path}'.format();
			
			_descriptions.set( p, desc );
			var ul	= ulr;
			for ( s in path ) {
				var child	= null;
				for ( j in 0...ul.childNodes.length ) {
					if ( s == ul.childNodes[ j ].firstChild.nodeValue ){
						child	= ul.childNodes[ j ].firstChild.nextSibling;
						break;
					}
				}
				if ( child != null )
					ul	= child;
				else
				{
					var ul2			= Lib.document.createElement( "ul" );
					ul2.className	= "tree";
					var li2 		= Lib.document.createElement( "li" );
					li2.className	= "tree";
					if ( s.endsWith( ".hxproj" ) )
					{
						var text	= Lib.document.createTextNode( s.substr( 0, -7 ) );
						a.appendChild( text );
						li2.appendChild( a );
					}
					else
						li2.appendChild( Lib.document.createTextNode( s ) );
					li2.appendChild( ul2 );
					ul.appendChild( li2 );
					ul	= ul2;
				}
			}
		}
		
		function rec( el : HtmlDom ) {
			for ( i in 0...el.childNodes.length ) {
				var child = el.childNodes[ i ];
				if ( child.nodeName == "LI" && child == el.lastChild )
					child.className += " last";
				
				if ( child.childNodes.length > 0 )
					rec( child );
			}
		}
		
		rec( ulr );
	}
	
	// FlashDevelop callback (recent projects list)
	public static function handleXmlData( s : String, rss : String ) {
		var fast 		= new Fast( Xml.parse( s ).firstElement() );
		_projects	= [];
		for ( p in fast.nodes.RecentProject ) {
			var path = p.node.Path.innerHTML.replace( "\\", "/" );
			path = path.substr( 0, 1 ).toLowerCase() + path.substr( 1 );
			var proj = { created : p.node.Created.innerHTML, modified : p.node.Modified.innerHTML, path : path };
			
			var exist = false;
			for ( i in _projects )
				if ( i.path == path ) {
					exist	= true;
					break;
				}
			if( !exist )
				_projects.push( proj );
				
			if ( _initialized )
				refresh();
		}
	}
}