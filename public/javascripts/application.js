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
