package body Shield_Octagon is

   function Full_Shields (Per_Facing : Shield_Points; Armor : Armor_Points)
     return Unit
   is
   begin
      return (Shields => [others => Per_Facing], Armor => Armor);
   end Full_Shields;

   procedure Apply_Energy
     (U : in out Unit; F : Facing; Damage : Damage_Points)
   is
   begin
      if Damage >= U.Shields (F) then
         U.Shields (F) := 0;
      else
         U.Shields (F) := U.Shields (F) - Damage;
      end if;
   end Apply_Energy;

   procedure Apply_Ballistic
     (U      : in out Unit;
      F      : Facing;
      Damage : Damage_Points;
      Pierce : Boolean := False)
   is
   begin
      if Pierce or else U.Shields (F) = 0 then
         if Damage >= U.Armor then
            U.Armor := 0;
         else
            U.Armor := U.Armor - Damage;
         end if;
      end if;
   end Apply_Ballistic;

   function Facing_Down (U : Unit; F : Facing) return Boolean is
   begin
      return U.Shields (F) = 0;
   end Facing_Down;

end Shield_Octagon;
