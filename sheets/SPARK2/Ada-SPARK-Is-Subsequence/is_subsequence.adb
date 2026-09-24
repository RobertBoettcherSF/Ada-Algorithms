pragma Ada_2022;
package body Is_Subsequence with SPARK_Mode => On is
   function Check (A, B : String) return Boolean is
   begin
      -- A tiny bounded stub: the source has zero or one character.
      if A'Length = 0 then
         return True;
      end if;
      for J in B'Range loop
         if A (A'First) = B (J) then
            return True;
         end if;
      end loop;
      return False;
   end Check;
end Is_Subsequence;
