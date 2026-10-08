pragma Ada_2022;

package body Standard_Score with SPARK_Mode => On is
   function Mean (Data : Sample_Array) return Sample is
      Total : Integer := 0;
   begin
      for I in Index loop
         Total := Total + Data (I);
      end loop;
      return Sample (Total / Sample_Count);
   end Mean;

   function Score (Data : Sample_Array; Position : Index) return Integer is
      Average : constant Sample := Mean (Data);
   begin
      if Data (Position) >= Average then
         return 10 * (Integer (Data (Position)) - Integer (Average));
      else
         return -10 * (Integer (Average) - Integer (Data (Position)));
      end if;
   end Score;
end Standard_Score;
