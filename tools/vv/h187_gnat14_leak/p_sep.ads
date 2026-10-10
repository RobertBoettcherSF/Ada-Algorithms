pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
--  Recursive Big_Integer expression function WITH a separate declaration
--  (the form of Partial in Different-Ways-To-Add-Parentheses-Lite).
package P_Sep is
   function W (N : Positive) return Big_Integer is
     (To_Big_Integer (case N is when 1 | 2 => 1, when 3 => 2, when 4 => 5, when others => 14));
   function Part (N : Positive; S : Natural) return Big_Integer;
   function Part (N : Positive; S : Natural) return Big_Integer is
     (if S = 0 then To_Big_Integer (0) else Part (N, S - 1) + W (S) * W (N - S));
end P_Sep;
