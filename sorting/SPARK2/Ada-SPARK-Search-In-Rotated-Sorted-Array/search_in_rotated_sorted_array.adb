pragma Ada_2022;

package body Search_In_Rotated_Sorted_Array with SPARK_Mode => On is
   function Contains (Data : Data_Array; Target : Value) return Boolean is
      Found : Boolean := False;
   begin
      for I in Index loop
         if Data (I) = Target then
            Found := True;
         end if;
      end loop;
      return Found;
   end Contains;
end Search_In_Rotated_Sorted_Array;
