pragma SPARK_Mode (On);

package body Longest_Mountain_In_Array is
   function Longest (Data : Values; Length : Length_Type) return Length_Type is
      Best : Length_Type := 0;
      Left : Length_Type;
      Right : Length_Type;
      Candidate : Length_Type;
   begin
      for Peak in Index loop
         exit when Peak > Length;
         Left := 0;
         Right := 0;
         if Peak > Index'First and then Peak < Length then
            for J in Index loop
               exit when J >= Peak;
               if J < Index'Last and then Data (J) < Data (J + 1) then
                  if Left < Length_Type'Last then
                     Left := Left + 1;
                  end if;
               else
                  Left := 0;
               end if;
            end loop;
            for J in Index loop
               exit when J >= Length;
               if J >= Peak then
                  if J < Index'Last and then Data (J) > Data (J + 1) then
                     if Right < Length_Type'Last then
                        Right := Right + 1;
                     end if;
                  else
                     exit;
                  end if;
               end if;
            end loop;
            if Left > 0 and then Right > 0
              and then Left + Right + 1 <= Length
            then
               Candidate := Length_Type (Left + Right + 1);
               if Candidate > Best then
                  Best := Candidate;
               end if;
            end if;
         end if;
      end loop;
      return Best;
   end Longest;
end Longest_Mountain_In_Array;
