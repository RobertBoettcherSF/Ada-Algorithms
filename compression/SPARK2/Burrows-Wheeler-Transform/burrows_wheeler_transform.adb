pragma Ada_2022;
package body Burrows_Wheeler_Transform with SPARK_Mode => On is
   function Rotation_Character
     (Input : Text; Start : Index; Offset : Rotation_Offset)
      return Character is
      Position : Index := Start;
   begin
      for Step in 1 .. Offset loop
         if Position = Index'Last then
            Position := Index'First;
         else
            Position := Position + 1;
         end if;
      end loop;
      return Input (Position);
   end Rotation_Character;

   function Rotation_Less (Input : Text; Left, Right : Index) return Boolean is
      Less : Boolean := False;
      Decided : Boolean := False;
   begin
      for Offset in 0 .. Max_Length - 1 loop
         if not Decided then
            declare
               L : constant Character := Rotation_Character (Input, Left, Offset);
               R : constant Character := Rotation_Character (Input, Right, Offset);
            begin
               if L < R then
                  Less := True;
                  Decided := True;
               elsif L > R then
                  Decided := True;
               end if;
            end;
         end if;
      end loop;
      return Less;
   end Rotation_Less;
end Burrows_Wheeler_Transform;
