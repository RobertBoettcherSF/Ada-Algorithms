pragma Ada_2022;
package body Damerau_Levenshtein_Distance
  with SPARK_Mode => On
is
   type DP_Row is array (Idx) of Natural;

   function Nat_Min (X, Y : Natural) return Natural with Global => null is
   begin
      if X <= Y then return X; else return Y; end if;
   end Nat_Min;

   function Inc (X : Natural) return Natural with Global => null is
   begin
      if X = Natural'Last then return X; else return X + 1; end if;
   end Inc;

   function Nat_Min3 (X, Y, Z : Natural) return Natural with Global => null is
   begin
      return Nat_Min (X, Nat_Min (Y, Z));
   end Nat_Min3;

   function Distance (A, B : Char_Array) return Natural is
      M : constant Len := A'Length;
      N : constant Len := B'Length;
      Prev2 : DP_Row := [others => 0];
      Prev  : DP_Row := [others => 0];
      Curr  : DP_Row := [others => 0];
      Cost  : Natural;
   begin
      if M = 0 then return N; end if;
      if N = 0 then return M; end if;

      for J in 0 .. N loop
         Prev (J) := J;
      end loop;

      for I in 1 .. M loop
         Curr (0) := I;
         for J in 1 .. N loop
            if A (I) = B (J) then Cost := 0; else Cost := 1; end if;
            Curr (J) := Nat_Min3
              (Inc (Prev (J)), Inc (Curr (J - 1)),
               (if Cost = 0 then Prev (J - 1) else Inc (Prev (J - 1))));
            if I >= 2 and then J >= 2
              and then A (I) = B (J - 1)
              and then A (I - 1) = B (J)
            then
               Curr (J) := Nat_Min (Curr (J), Inc (Prev2 (J - 2)));
            end if;
         end loop;
         for J in 0 .. N loop
            Prev2 (J) := Prev (J);
            Prev (J) := Curr (J);
         end loop;
      end loop;
      return Prev (N);
   end Distance;
end Damerau_Levenshtein_Distance;
