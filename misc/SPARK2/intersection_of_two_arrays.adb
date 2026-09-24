pragma SPARK_Mode (On);

package body Intersection_Of_Two_Arrays is
   function Count (Left : Values; Right : Values) return Count_Type is
      Matches : Count_Type := 0;
      Found : Boolean;
   begin
      for I in Index loop
         pragma Loop_Invariant (Matches <= I - 1);
         Found := False;
         for J in Index loop
            if Left (I) = Right (J) then
               Found := True;
            end if;
         end loop;
         if Found then
            Matches := Matches + 1;
         end if;
      end loop;
      return Matches;
   end Count;
end Intersection_Of_Two_Arrays;
