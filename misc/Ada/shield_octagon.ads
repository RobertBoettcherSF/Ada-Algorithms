-- Clean-room educational shield model: eight facings.
-- Energy drains a facing; ballistic hits armor when that facing is 0;
-- optional pierce damages armor through remaining shield.
-- Generic unit terms only (Mech / Tank / Grav_Tank — not proprietary names).

package Shield_Octagon is

   pragma Pure;

   type Facing is range 1 .. 8;

   subtype Shield_Points is Natural;
   subtype Armor_Points  is Natural;
   subtype Damage_Points is Natural;

   type Facings is array (Facing) of Shield_Points;

   type Unit is record
      Shields : Facings      := [others => 0];
      Armor   : Armor_Points := 0;
   end record;

   -- Optional chassis label for fixtures (generic terms only).
   type Chassis_Kind is (Mech, Tank, Grav_Tank);

   function Full_Shields
     (Per_Facing : Shield_Points; Armor : Armor_Points) return Unit;

   procedure Apply_Energy
     (U : in out Unit; F : Facing; Damage : Damage_Points);

   -- Ballistic: if Pierce, damage armor directly; else only when facing is 0.
   procedure Apply_Ballistic
     (U      : in out Unit;
      F      : Facing;
      Damage : Damage_Points;
      Pierce : Boolean := False);

   function Facing_Down (U : Unit; F : Facing) return Boolean;

end Shield_Octagon;
