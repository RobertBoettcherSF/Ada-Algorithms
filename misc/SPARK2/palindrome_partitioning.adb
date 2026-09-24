pragma SPARK_Mode (On);

package body Palindrome_Partitioning is
   function Is_Palindrome (A : Word; N : Length) return Boolean is
      Good : Boolean := True;
   begin
      for I in 1 .. N / 2 loop
         if A (I) /= A (N - I + 1) then
            Good := False;
         end if;
      end loop;
      return Good;
   end Is_Palindrome;

   function Minimum_Cuts (A : Word; N : Length) return Length is
   begin
      if N = 0 or else Is_Palindrome (A, N) then
         return 0;
      elsif N = 1 then
         return 0;
      else
         return N - 1;
      end if;
   end Minimum_Cuts;
end Palindrome_Partitioning;
