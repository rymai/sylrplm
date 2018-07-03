// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function selectInOutFill(select_ref_id) {
	//alert('selectInOutFill:'+select_ref_id);
	select_from = byId(select_ref_id);
	select_to = byId(select_ref_id + '_in');
	selectInOutFill_(select_from, select_to, 'in');
	select_to = byId(select_ref_id + '_out');
	selectInOutFill_(select_from, select_to, 'out');
	// we add a blank option to return something at submit when the list is empty
	newopt = document.createElement("option");
	newopt.value = '';
	select_from.appendChild(newopt);
	newopt.selected=true;
}

function selectInOutFill_(select_from, select_to, in_out) {
	if(in_out == 'in') {
		ifselect = true;
	} else {
		ifselect = false;
	}
	var length_from = select_from.length;
	//alert('selectInOutFill_:'+select_from+":"+ select_from.length);
	if(!length_from)
		return null;
	for(var i = 0; i < length_from; i++) {
		var opt = select_from.options[i];
		if(opt.selected == ifselect) {
			newopt = document.createElement("option")
			newopt.value = opt.value
			newopt.innerHTML = opt.innerHTML
			select_to.appendChild(newopt);
		}
	}
		
}

function selectInOutAdd(select_id) {
	select_ref = byId(select_id);
	select_from = byId(select_id + "_out");
	select_to = byId(select_id + "_in");
	selectInOutMove_(select_ref, select_from, select_to, true);
}

function selectInOutRemove(select_id) {
	select_ref = byId(select_id);
	select_from = byId(select_id + "_in");
	select_to = byId(select_id + "_out");
	selectInOutMove_(select_ref, select_from, select_to, false);
}

function selectInOutMove_(select_ref, select_from, select_to, to_select) {
	var length_ref = select_ref.length;
	var length_from = select_from.length;
	var length_to = select_to.length;
	//alert('selectInOutMove_: ref='+length_ref+' from='+length_from+' to='+length_to);
	if(!length_ref || !length_from)
		return null;
	var i = 0;
	var to_move = [];
	for( i = 0; i < length_from; i++) {
		var opt = select_from.options[i];
		if(opt.selected) {
			for(var j = 0; j < length_ref; j++) {
				var opt_ref = select_ref.options[j];
				if(opt.value == opt_ref.value) {
					opt_ref.selected = to_select;
				}
			}
			opt.selected = false;
			to_move.push(opt)
		}
	}
	for( i = 0; i < to_move.length; i++) {
		select_to.appendChild(to_move[i]);
	}
	/*
	var nbref=0;
	for( i = 0; i < select_ref.length; i++) {
		var opt = select_ref.options[i];
		if(opt.selected) {
			nbref+=1;
		}
	}
	alert('selectInOutMove_: ref='+select_ref.name+':'+nbref);
	*/
}

var select_html;
function selectActive(check, select_id) {
	var select = byId(select_id);
	if(select) {
		//select.readonly = (check.checked ? undefined : "readonly");
		//alert ('selectActive:check='+check.checked+' select='+select.readonly)
		if(select.innerHTML) {
			select_html = select.innerHTML
		}
		if(!check.checked) {
			select.innerHTML = null;
		} else {
			select.innerHTML = select_html
		}
	}
}

/*
 * use by helper select_in_list
 * met a jour un champ de la fenetre appelante
 * appelle par les vues index utilisees en mode (todo) select
 * @param html_ident: id (au sens html) du champ a mettre a jour
 * @param id: id (au sens bd) du champ a mettre a jour
 * @param display: valeur a afficher dans le champ
 */
function callSelect(html_ident, id, display) {
	win=top.opener;
	field_id=win.document.getElementById(html_ident+'_id');
	field_display=win.document.getElementById(html_ident+'_display');
	//alert ('win='+win+' html_ident='+html_ident+':'+field_id.value+' display='+field_display.value);
	field_id.value=id;
	field_display.value=display;
	//alert (' id='+field_id.value+' display='+field_display.value);
	window.close();
	win.focus();
	
}