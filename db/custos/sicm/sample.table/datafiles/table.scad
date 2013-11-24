use <plateau_rectangulaire.scad>;
use <pied_carre_long.scad>;
module table()
{
translate([40,25,-1.75]) pied_carre_long();
translate([-40,25,-1.75]) pied_carre_long();
translate([40,-25,-1.75]) pied_carre_long();
translate([-40,-25,-1.75]) pied_carre_long();
plateau_rectangulaire();
}

table();

