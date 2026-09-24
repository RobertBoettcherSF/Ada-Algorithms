pragma Ada_2022;
package body Levenshtein_Distance
  with SPARK_Mode => On
is
   type DP_Row is array (Idx) of Natural;

   function Nat_Min (X, Y : Natural) return Natural
     with Global => null
   is
   begin
      if X <= Y then
         return X;
      else
         return Y;
      end if;
   end Nat_Min;

   function Nat_Min3 (X, Y, Z : Natural) return Natural
     with Global => null
   is
   begin
      return Nat_Min (X, Nat_Min (Y, Z));
   end Nat_Min3;

   function Distance (A, B : Char_Array) return Natural is
      M    : constant Len := A'Length;
      N    : constant Len := B'Length;
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
      end loop;

      for I in 1 .. M loop
         Curr (0) := I;
         for J in 1 .. N loop
            if A (I) = B (J) then
               Cost := 0;
            else
               Cost := 1;
            end if;
            Curr (J) := Nat_Min3
              (Prev (J) + 1,
               Curr (J - 1) + 1,
               Prev (J - 1) + Cost);
         end loop;
         for J in 0 .. N loop
            Prev (J) := Curr (J);
         end loop;
      end loop;

      return Prev (N);
   end Distance;

end Levenshtein_Distance;
