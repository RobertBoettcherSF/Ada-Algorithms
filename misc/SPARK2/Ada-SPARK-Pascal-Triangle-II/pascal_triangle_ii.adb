pragma SPARK_Mode (On);

package body Pascal_Triangle_II is
   function Add_Bounded (Left, Right : Result) return Result is
   begin
      if Left > Result'Last - Right then
         return Result'Last;
      else
         return Left + Right;
      end if;
   end Add_Bounded;

   function Get (Row_Number : Row_Index; Column : Row_Index) return Result is
      Values : Row := (others => 0);
   begin
      Values (0) := 1;
      for R in 1 .. Row_Number loop
         pragma Loop_Invariant (Values'First = 0 and Values'Last = 32);
         for C in reverse 1 .. R loop
            Values (C) := Add_Bounded (Values (C), Values (C - 1));
         end loop;
      end loop;
      if Column <= Row_Number then
         return Values (Column);
      else
         return 0;
      end if;
   end Get;
end Pascal_Triangle_II;
