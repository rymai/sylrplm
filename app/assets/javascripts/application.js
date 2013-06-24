//= require 'jquery'
//= require 'bootstrap'
//= require 'tree'
//= require 'sylrplm_extensions'
//
// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function hideTreeMenu() {

	Element.toggle('dtree');
	if (Element.visible('dtree')) {

		Element.setStyle('content', {
			marginLeft : "210px"
		});
	} else {

		Element.setStyle('content', {
			marginLeft : "5px"
		});
	};
};

function openCloseAllTree(tree) {
	tree.oAll(!tree.root._io);
};

var helpWin;
var helpClick;
//
function helpTip() {
	helpClick = 1;
	Element.setStyle('menu', {
		cursor : "help"
	});
}

function helpPopup(which, href) {

	if (helpClick != 1 && href != null) {
		//alert('helpPopup:which=' + which + ' helpWin=' + helpWin + ' helpClick=' + helpClick + ' href=' + href);
		Element.setStyle('menu', {
			cursor : "pointer"
		});
		window.location = href;
	} else {

		if (which == null)
			which = "help_contents_help";
		if ((!helpWin) || (helpWin.closed)) {
			//alert ('helpPopup:open which='+which+' helpWin='+helpWin+' helpClick='+helpClick+' href='+href);
			//helpWin = window.open("/help?help="+which, which,"location=no, menubar=no, status=no, scrollbars=no, resizable=no, directories=yes, menubar=no, toolbar=no, width=500, height=320, left=50, top=50");
			helpWin = window.open("/help?help=" + which, which, "width=500,height=320,left=50,top=50, scrollbars=yes,resizable=yes, directories=yes");
		} else {
			helpWin.location = '/help?help=' + which;
		}
		helpClick = 0;
		Element.setStyle('menu', {
			cursor : "pointer"
		});
	};
	return false;
};

function helpWindow(which) {

	if (which == null) {
		which = "help_contents_help";
	}
	//alert ('helpPopup:open which='+which+' helpWin='+helpWin );
	if (!helpWin || helpWin.closed) {
		//alert ('helpPopup:open which='+which+' helpWin='+helpWin+' helpClick='+helpClick+' href='+href);
		//helpWin = window.open("/help?help="+which, which,"location=no, menubar=no, status=no, scrollbars=no, resizable=no, directories=yes, menubar=no, toolbar=no, width=500, height=320, left=50, top=50");
		// les dimensions ne sont pas prises en compte sur firefox, la fenetre est maximisée
		helpWin = window.open('/help?help=' + which, which, 'scrollbars=yes,resizable=yes,width=500,height=320,left=50');

	} else {
		helpWin.location = '/help?help=' + which;
	}
	return false;
};

function getHelp(which) {
	if ((helpWin) && (!helpWin.closed))
		helpWin.location = 'help?help=' + which;
}

function closeHelp() {
	if (helpWin) {
		alert ('closeHelp');
		helpWin.close();
	}
}

// ruote-web2

// $(whatever) style
//
function byId(i) {
	return document.getElementById(i);
}

// I know, but let's get js framework independent

// links to a CSS file (in the document <HEAD/>)
//
function linkToCss(href) {

	var e = document.createElement('link');
	e.setAttribute('href', '/stylesheets/' + href + '.css');
	e.setAttribute('media', 'screen');
	e.setAttribute('rel', 'stylesheet');
	e.setAttribute('type', 'text/css');
	var h = document.getElementsByTagName('head')[0];

	h.appendChild(e);

	h.insertBefore(e, h.firstChild);
	// making sure that controller-related css are placed last
}

// when 'enter' is hit, will call 'func'
//
function onEnter(field, evt, func) {
	var e = evt || window.event;
	var c = e.charCode || e.keyCode;
	if (c == 13)
		func();
	return false;
}

function filterEnterKeyOut(evt) {
	var e = evt || window.event;
	var c = e.charCode || e.keyCode;
	return (c != 13);
}

function toggleVisibility(i) {
	var e = i;
	if (( typeof e) == 'string')
		e = byId(i);
	if (e.style.display == 'block')
		e.style.display = 'none';
	else
		e.style.display = 'block';
	return (e.style.display == 'block');
	// true if now visible
}

function toggleHelp() {
	var h = document.getElementById('help');
	if (!h)
		return;
	toggleVisibility(h);
}

function updateField(id, i_value) {
	el = byId(id);
	el.value = i_value;
}

function updateRelation() {
	var relation_name = byId('relation_name');
	var relation_father_plmtype = byId('relation_father_plmtype');
	var relation_child_plmtype = byId('relation_child_plmtype');
	var relation_father_type_id = byId('relation_father_type_id');
	var relation_child_type_id = byId('relation_child_type_id');
	if (relation_name == null)
		return;
	if (relation_father_plmtype == null)
		return;
	if (relation_child_plmtype == null)
		return;
	if (relation_father_type_id == null)
		return;
	if (relation_child_type_id == null)
		return;

	var sep_type = "."
	var sep_child = "-"

	var father_selected = relation_father_type_id.options[0].text
	for ( i = 0; i < relation_father_type_id.length; i++) {
		if (relation_father_type_id.options[i].value == relation_father_type_id.value) {
			father_selected = relation_father_type_id.options[i].text
		}
	}
	var child_selected = relation_child_type_id.options[0].text
	for ( i = 0; i < relation_child_type_id.length; i++) {
		if (relation_child_type_id.options[i].value == relation_child_type_id.value) {
			child_selected = relation_child_type_id.options[i].text
		}
	}
	var val = relation_father_plmtype.value;
	val = val + sep_type + father_selected;
	val = val + sep_child + relation_child_plmtype.value;
	val = val + sep_type + child_selected;
	//alert ('updateRelation val='+val);
	if (relation_name.value.indexOf(val) == -1) {
		//syl:on garde le nom tel quel, relation_name.value = val;
	}
}

function doLoad(i_params) {
	var params = JSON.parse(i_params)
	//alert('params=' + params+' ,controller='+params.controller+' ,action='+params.action+' ,id='+params.id);

}

function doUnload() {
	// Do something when document is about to be unloaded.
}

