module vis()
{
	rotate([0,180,0]) {
union() {
		translate(0,0,-10) {
			cylinder(h = 3.5, r=1);
		}
		cylinder(h = 1, r=2);
	}
}
}


