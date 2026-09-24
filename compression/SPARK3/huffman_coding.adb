pragma Ada_2022;
package body Huffman_Coding
  with SPARK_Mode => On
is
   function Count_Frequencies (Data : Symbol_Array) return Freq_Map is
      F : Freq_Map := [others => 0];
   begin
      for I in Data'Range loop
         pragma Loop_Invariant
           (for all S in Symbol => F (S) <= I - Data'First);
         F (Data (I)) := F (Data (I)) + 1;
      end loop;
      return F;
   end Count_Frequencies;

   function Distinct_Count (F : Freq_Map) return Natural is
      subtype Count is Natural range 0 .. 26;
      N : Count := 0;
   begin
      for S in Symbol loop
         pragma Loop_Invariant (N <= 26);
         if F (S) > 0 and then N < 26 then
            N := N + 1;
         end if;
      end loop;
      return Natural (N);
   end Distinct_Count;

   function Most_Frequent (F : Freq_Map) return Symbol is
      Best : Symbol := 'a';
   begin
      for S in Symbol loop
         if F (S) > F (Best) then
            Best := S;
         end if;
      end loop;
      return Best;
   end Most_Frequent;

end Huffman_Coding;
