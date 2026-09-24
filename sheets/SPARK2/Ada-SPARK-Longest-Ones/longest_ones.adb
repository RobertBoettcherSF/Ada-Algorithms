pragma SPARK_Mode (On);
package body Longest_Ones is
   function Find (Bits : Bit_Array; Flips : Count) return Count is
      Best : Count := 0;
      Zeroes : Count;
      Length : Count;
   begin
      for Start in Index loop
         Zeroes := 0;
         for Finish in Index loop
            if Finish >= Start then
               if Bits (Finish) = 0 and then Zeroes < Count'Last then
                  Zeroes := Zeroes + 1;
               end if;
               if Zeroes <= Flips then
                  Length := Finish - Start + 1;
                  if Length > Best then Best := Length; end if;
               end if;
            end if;
         end loop;
      end loop;
      return Best;
   end Find;
end Longest_Ones;
