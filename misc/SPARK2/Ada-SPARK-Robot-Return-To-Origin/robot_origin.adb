pragma Ada_2022;

package body Robot_Origin with SPARK_Mode => On is
function Returns_To_Origin (Moves : Text; Length : Length_Type) return Boolean is
      X : Integer range -32 .. 32 := 0;
      Y : Integer range -32 .. 32 := 0;
   begin
      for I in Index loop
         exit when I > Length;
         case Moves (I) is
            when 'U' =>
               if Y < 32 then Y := Y + 1; end if;
            when 'D' =>
               if Y > -32 then Y := Y - 1; end if;
            when 'L' =>
               if X > -32 then X := X - 1; end if;
            when 'R' =>
               if X < 32 then X := X + 1; end if;
            when others =>
               return False;
         end case;
      end loop;
      return X = 0 and then Y = 0;
   end Returns_To_Origin;
end Robot_Origin;
