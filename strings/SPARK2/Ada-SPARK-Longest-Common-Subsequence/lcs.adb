pragma Ada_2022;
package body LCS
  with SPARK_Mode => On
is
   --  Row (K) = length of an LCS of the first I characters of A and the
   --  first K characters of B. An LCS can never be longer than either
   --  prefix, so every cell fits in Len (0 .. Max_Len).
   type Row is array (0 .. Max_Len) of Len;

   function Nat_Max (X, Y : Len) return Len is
     (if X >= Y then X else Y)
     with Global => null;

   function Length (A, B : Char_Array) return Natural is
      M : constant Len := A'Length;
      N : constant Len := B'Length;
      Prev : Row := [others => 0];
      Curr : Row := [others => 0];
   begin
      if M = 0 or else N = 0 then
         return 0;
      end if;
      for I in 1 .. M loop
         --  Prev holds row I - 1: no cell exceeds I - 1 or its own column.
         pragma Loop_Invariant
           (for all K in Row'Range => Prev (K) <= I - 1 and then Prev (K) <= K);
         pragma Loop_Invariant
           (for all K in Row'Range => Curr (K) <= I - 1 and then Curr (K) <= K);
         Curr (0) := 0;
         for J in 1 .. N loop
            --  Cells 1 .. J - 1 are already row I (<= I); the rest still
            --  hold row I - 1 (<= I - 1 <= I). Both stay below the column.
            pragma Loop_Invariant
              (for all K in Row'Range => Curr (K) <= I and then Curr (K) <= K);
            if A (I) = B (J) then
               Curr (J) := Prev (J - 1) + 1;
            else
               Curr (J) := Nat_Max (Prev (J), Curr (J - 1));
            end if;
         end loop;
         Prev := Curr;
      end loop;
      return Prev (N);
   end Length;
end LCS;
