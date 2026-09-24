pragma Ada_2022;
package body Shortest_Unsorted_Continuous_Subarray with SPARK_Mode => On is
   function Unsorted_Span (A : Int_Array) return Count is
      First : Count := 0;
      Last : Count := 0;
   begin
      for I in Index range Index'First .. Index'Last - 1 loop
         if A (I) > A (I + 1) then
            if First = 0 then
               First := Count (I);
            end if;
            Last := Count (I) + 1;
         end if;
      end loop;
      if First = 0 then
         return 0;
      elsif Last >= First then
         return Count (Last - First + 1);
      else
         return 0;
      end if;
   end Unsorted_Span;
end Shortest_Unsorted_Continuous_Subarray;
