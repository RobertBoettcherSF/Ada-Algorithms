pragma Ada_2022;

package body Pangram with SPARK_Mode => On is
function Is_Pangram (Input : Text; Length : Length_Type) return Boolean is
      Seen : array (Character range 'a' .. 'z') of Boolean := (others => False);
   begin
      for I in Index loop
         exit when I > Length;
         if Input (I) in 'a' .. 'z' then
            Seen (Input (I)) := True;
         end if;
      end loop;
      for C in Seen'Range loop
         if not Seen (C) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Pangram;
end Pangram;
