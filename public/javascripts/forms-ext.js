linkToCss('ruote-forms');
//var options = new Object();
//options['buttons'] = 'position';
function swapForm() {
	var fta = byId('fields_ta');
	var ffl = byId('fields');
	var frf = byId('fields_rf');
	var brf = byId('rf_buttons');
	if(fta.style.display == 'block') {
		RuoteForms.renderForm('rform', fluoFromJson(ffl.value));
		fta.style.display = 'none';
		frf.style.display = 'block';
		brf.style.display = 'inline';
	} else {
		ffl.value = RuoteForms.toJson('rform');
		fta.style.display = 'block';
		frf.style.display = 'none';
		brf.style.display = 'none';
	}
}