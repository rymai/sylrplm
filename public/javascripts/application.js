// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
function hideTreeMenu(){

 	Element.toggle('dtree');
 	if (Element.visible('dtree')) {
 	
 		Element.setStyle('content', {marginLeft: "210px"});
	} else {
	
		Element.setStyle('content', {marginLeft: "5px"});
	};
};

var helpWin;
var helpClick;
//
function helpTip() {
	helpClick=1;
	Element.setStyle('menu', {cursor: "help"});
}

function helpPopup(which, href) {
	//alert ('which='+which+' helpWin='+helpWin+' helpClick='+helpClick+' href='+href);
	if(helpClick!=1 && href!=null) {
		
	    Element.setStyle('menu', {cursor: "pointer"});
		window.location=href;
	} else {
		
		if (which==null) which = "help_contents_help";
		if ((!helpWin)||(helpWin.closed)) {
			helpWin = window.open('/help?help='+which,'','left=50,top=50,width=500,height=320,resizable=1,scrollbars=1');
		} else {
			helpWin.location = '/help?help='+which;
		}
		helpClick=0;
		Element.setStyle('menu', {cursor: "pointer"});
	};
	return false;
};

function helpPopup_old(which, href) {
	
	if (which==null) which = "help_contents_help";
	if ((!helpWin)||(helpWin.closed)) helpWin = window.open('/help?help='+which,'','left=50,top=50,width=500,height=320,resizable=1,scrollbars=1');
	else helpWin.location = '/help?help='+which;
	
	return false;
}
function getHelp(which) {
	if ((helpWin)&&(!helpWin.closed)) helpWin.location='help?help='+which;
}
function closeHelp() {
	if (helpWin) helpWin.close();
}

// ruote-web2

// $(whatever) style
//
function byId (i) { return document.getElementById(i); } 
  // I know, but let's get js framework independent

// links to a CSS file (in the document <HEAD/>)
//
function linkToCss (href) {

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
function onEnter (field, evt, func) {
  var e = evt || window.event;
  var c = e.charCode || e.keyCode;
  if (c == 13) func();
  return false;
}

function filterEnterKeyOut (evt) {
  var e = evt || window.event;
  var c = e.charCode || e.keyCode;
  return (c != 13);
}

function toggleVisibility (i) {
  var e = i;
  if ((typeof e) == 'string') e = byId(i);
  if (e.style.display == 'block') e.style.display = 'none';
  else e.style.display = 'block';
  return (e.style.display == 'block'); // true if now visible
}

function toggleHelp () {
  var h = document.getElementById('help');
  if ( ! h) return;
  toggleVisibility(h);
}


