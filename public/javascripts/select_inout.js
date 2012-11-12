// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


function selectInOutFill(select_ref_id) {
		select_from=byId(select_ref_id);
		select_to=byId(select_ref_id+'_in');
		selectInOutFill_(select_from,select_to, 'in' );
		select_to=byId(select_ref_id+'_out');
		selectInOutFill_(select_from,select_to, 'out' );
}

function selectInOutFill_(select_from, select_to, in_out) {
	if (in_out=='in') {
		ifselect=true;
	} else{
		ifselect=false;	
	}
	var length_from = select_from.length;
  if (!length_from) return null;
  for (var i = 0; i < length_from; i++) {
    var opt = select_from.options[i];
    if (opt.selected==ifselect) {
    	newopt=document.createElement("option")
    	newopt.value=opt.value
    	newopt.innerHTML=opt.innerHTML
    	select_to.appendChild(newopt);
    }
  }
}

function selectInOutAdd(select_id) {
	select_ref= byId(select_id);
	select_from = byId(select_id+"_out");
	select_to = byId(select_id+"_in");
	selectInOutMove_(select_ref, select_from, select_to, true);
}

function selectInOutRemove(select_id) {
	select_ref= byId(select_id);
	select_from = byId(select_id+"_in");
	select_to = byId(select_id+"_out");
	selectInOutMove_(select_ref, select_from, select_to, false);
}

function selectInOutMove_(select_ref, select_from, select_to, to_select) {
	var length_ref = select_ref.length;
	var length_from = select_from.length;
	var length_to = select_to.length;
  if (!length_ref || !length_from) return null;
  var i=0;
  var to_move=[];
  for (i = 0; i < length_from; i++) {
    var opt = select_from.options[i];
    if (opt.selected) {
    	for (var j = 0; j < length_ref; j++) {
		    var opt_ref = select_ref.options[j];
		    if (opt.value==opt_ref.value) {
		    	opt_ref.selected=to_select;
		    }
  		}
  		opt.selected=false;
  		to_move.push(opt)
    }
  }
  for (i=0;i<to_move.length;i++) {
  	select_to.appendChild(to_move[i]);
  }
}




