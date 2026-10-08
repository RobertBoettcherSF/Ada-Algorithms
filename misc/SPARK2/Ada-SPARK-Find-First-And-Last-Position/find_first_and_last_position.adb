pragma Ada_2022;

package body Find_First_And_Last_Position with SPARK_Mode => On is
   function Locate (Data : Sorted_Array; Target : Value) return Match_Range is
      Answer : Match_Range := (First => 0, Last => 0);
   begin
      for I in Index loop
         if Data (I) = Target then
            if Answer.First = 0 then
               Answer.First := I;
            end if;
            Answer.Last := I;
         end if;
      end loop;
      return Answer;
   end Locate;
end Find_First_And_Last_Position;
