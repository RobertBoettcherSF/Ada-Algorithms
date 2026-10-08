pragma Ada_2022;
pragma SPARK_Mode (On);
package body Palindrome_Partitioning is
   function Is_Palindrome (A : Word; First, Last : Positive) return Boolean
     with Pre => First <= Last and then Last <= 4
   is
   begin
      for I in 0 .. (Last - First) / 2 loop
         if A (First + I) /= A (Last - I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Palindrome;

   --  Pieces (I) = fewest palindromic pieces covering A (1 .. I); the answer is Pieces (N) - 1 cuts.
   function Minimum_Cuts (A : Word; N : Length) return Length is
      Pieces : array (0 .. 4) of Length := [others => 0];
   begin
      if N = 0 then
         return 0;
      end if;
      for I in 1 .. N loop
         pragma Loop_Invariant (Pieces (0) = 0
                                and then (for all K in 1 .. I - 1 => Pieces (K) in 1 .. K));
         Pieces (I) := I;   --  one letter per piece
         for J in 1 .. I loop   --  last piece A (J .. I)
            pragma Loop_Invariant (Pieces (0) = 0 and then Pieces (I) in 1 .. I
                                   and then (for all K in 1 .. I - 1 => Pieces (K) in 1 .. K));
            if Is_Palindrome (A, J, I) and then Pieces (J - 1) + 1 < Pieces (I) then
               Pieces (I) := Pieces (J - 1) + 1;
            end if;
         end loop;
      end loop;
      return Pieces (N) - 1;
   end Minimum_Cuts;
end Palindrome_Partitioning;
