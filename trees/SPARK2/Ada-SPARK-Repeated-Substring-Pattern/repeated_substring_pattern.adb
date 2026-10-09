pragma Ada_2022;

package body Repeated_Substring_Pattern with SPARK_Mode => On is

   function Period_Holds (Input : Text_Array; P : Positive) return Boolean
     with Post => Period_Holds'Result = Has_Period (Input, P)
   is
   begin
      if Input'Length <= P then
         return True;
      end if;
      for I in Input'First + P .. Input'Last loop
         if Input (I) /= Input (I - P) then
            return False;
         end if;
         pragma Loop_Invariant
           (for all J in Input'First .. I =>
              (if J - Input'First >= P then Input (J) = Input (J - P)));
      end loop;
      return True;
   end Period_Holds;

   function Is_Repeated (Input : Text_Array) return Boolean is
      N : constant Natural := Input'Length;
   begin
      for P in 1 .. N / 2 loop
         if N mod P = 0 and then Period_Holds (Input, P) then
            pragma Assert (Repeats_Unit (Input, P));
            return True;
         end if;
         pragma Assert (not Repeats_Unit (Input, P));
         pragma Loop_Invariant
           (for all Q in 1 .. P => not Repeats_Unit (Input, Q));
      end loop;
      pragma Assert (for all Q in 1 .. N / 2 => not Repeats_Unit (Input, Q));
      return False;
   end Is_Repeated;
end Repeated_Substring_Pattern;
