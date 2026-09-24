pragma Ada_2022;

package body Find_Minimum_In_Rotated_Sorted_Array with SPARK_Mode => On is
   function Minimum (Data : Data_Array) return Value is
      Answer : Value := Data (Index'First);
   begin
      for I in Index range 2 .. Index'Last loop
         if Data (I) < Answer then
            Answer := Data (I);
         end if;
      end loop;
      return Answer;
   end Minimum;
end Find_Minimum_In_Rotated_Sorted_Array;
