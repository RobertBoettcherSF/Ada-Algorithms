pragma Ada_2022;

package body Formed_Words with SPARK_Mode => On is
function Can_Be_Formed
     (Available        : Text;
      Available_Length : Length_Type;
      Word              : Text;
      Word_Length      : Length_Type) return Boolean is
      type Counts is array (Character range 'a' .. 'z') of Natural range 0 .. 32;
      Remaining : Counts := (others => 0);
   begin
      for I in Index loop
         exit when I > Available_Length;
         if Available (I) in 'a' .. 'z' then
            if Remaining (Available (I)) = 32 then
               return False;
            end if;
            Remaining (Available (I)) := Remaining (Available (I)) + 1;
         else
            return False;
         end if;
      end loop;
      for I in Index loop
         exit when I > Word_Length;
         if Word (I) not in 'a' .. 'z' then
            return False;
         elsif Remaining (Word (I)) = 0 then
            return False;
         else
            Remaining (Word (I)) := Remaining (Word (I)) - 1;
         end if;
      end loop;
      return True;
   end Can_Be_Formed;
end Formed_Words;
