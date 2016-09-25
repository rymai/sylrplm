linkToCss('ruote-forms');
//var options = new Object();
//options['buttons'] = 'position';
function swapForm(btswap_value, btswap_code) {
	var bt_swap = byId('button_swap');
	var fta = byId('fields_ta');
	var ffl = byId('fields');
	var frf = byId('fields_rf');
	var brf = byId('rf_buttons');
	//alert('>>>swapForm'+fta.style.display+":"+ffl.value+' button_swap='+bt_swap+":"+bt_swap.value+' args='+btswap_value+', '+btswap_code);
	if(fta.style.display == 'block') {
		bt_swap.text=btswap_code;
		RuoteForms.renderForm('rform', fluoFromJson(ffl.value));
		fta.style.display = 'none';
		frf.style.display = 'block';
		brf.style.display = 'inline';
	} else {
		bt_swap.text=btswap_value;
		ffl.value = RuoteForms.toJson('rform');
		fta.style.display = 'block';
		frf.style.display = 'none';
		brf.style.display = 'none';
	}
	//alert('<<<swapForm'+fta.style.display+":"+ffl.value+' button_swap='+bt_swap+":"+bt_swap.value+' args='+btswap_value+', '+btswap_code);
}