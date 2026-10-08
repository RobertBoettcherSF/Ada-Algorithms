pragma SPARK_Mode (On);

package body Three_Sum_Closest is
   function Distance (Left, Right : Sum_Value) return Natural is
   begin
      if Left >= Right then
         return Left - Right;
      else
         return Right - Left;
      end if;
   end Distance;

   function Closest (Data : Values; Length : Length_Type; Target : Target_Value)
     return Sum_Value is
      Best : Sum_Value := 0;
      Candidate : Sum_Value;
      Have_Best : Boolean := False;
   begin
      for I in Index loop
         exit when I > Length;
         for J in Index loop
            exit when J > Length;
            for K in Index loop
               exit when K > Length;
               if I < J and then J < K then
                  Candidate := Sum_Value (Data (I) + Data (J) + Data (K));
                  if not Have_Best
                    or else Distance (Candidate, Sum_Value (Target))
                              < Distance (Best, Sum_Value (Target))
                  then
                     Best := Candidate;
                     Have_Best := True;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
      return Best;
   end Closest;
end Three_Sum_Closest;
