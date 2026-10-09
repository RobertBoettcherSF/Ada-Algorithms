pragma Ada_2022;
package body Levenshtein_Distance
  with SPARK_Mode => On
is
   type DP_Row is array (Idx) of Natural;

   function Nat_Min3 (X, Y, Z : Natural) return Natural is
     (Natural'Min (X, Natural'Min (Y, Z)))
   with Global => null;

   function Distance (A, B : Char_Array) return Natural is
      M    : constant Len := A'Length;
      N    : constant Len := B'Length;
      AO   : constant Integer := A'First - 1;   --  A (AO + I) is the I-th
      --  Integer: an empty A may have A'First = 0 (null arrays need not
      --  have bounds in Positive).
      BO   : constant Integer := B'First - 1;
      Prev : DP_Row := [others => 0];
      Curr : DP_Row := [others => 0];
      Cost : Natural;
   begin
      if M = 0 then
         return N;
      end if;
      if N = 0 then
         return M;
      end if;

      for J in 0 .. N loop
         Prev (J) := J;
         pragma Loop_Invariant (for all K in 0 .. J => Prev (K) <= K);
      end loop;

      --  Row I holds distances from A's first I characters; an entry
      --  never exceeds the lengths compared (all deletes then inserts).
      for I in 1 .. M loop
         pragma Loop_Invariant (for all K in 0 .. N => Prev (K) <= (I - 1) + K);
         Curr (0) := I;
         for J in 1 .. N loop
            pragma Loop_Invariant (for all K in 0 .. J - 1 => Curr (K) <= I + K);
            if A (AO + I) = B (BO + J) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            Curr (J) := Nat_Min3
              (Prev (J) + 1,
               Curr (J - 1) + 1,
               Prev (J - 1) + Cost);
         end loop;
         Prev := Curr;
      end loop;

      return Prev (N);
   end Distance;

end Levenshtein_Distance;
