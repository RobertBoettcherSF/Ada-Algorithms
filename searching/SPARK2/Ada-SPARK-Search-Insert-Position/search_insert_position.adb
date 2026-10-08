pragma Ada_2022;

package body Search_Insert_Position with SPARK_Mode => On is
   function Position (Data : Sorted_Array; Target : Value) return Insertion_Index is
      Answer : Insertion_Index := Insertion_Index'Last;
   begin
      for I in Index loop
         if Answer = Insertion_Index'Last and then Data (I) >= Target then
            Answer := I;
         end if;
      end loop;
      return Answer;
   end Position;
end Search_Insert_Position;
