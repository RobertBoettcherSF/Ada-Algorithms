pragma Ada_2022;

package body Find_The_Duplicate_Number with SPARK_Mode => On is
   function Duplicate (Input : Input_Array) return Element is
   begin
      for I in Index loop
         for J in Index loop
            if J < I and then Input (J) = Input (I) then
               return Input (I);
            end if;
         end loop;
      end loop;
      return Input (Index'First);
   end Duplicate;
end Find_The_Duplicate_Number;
