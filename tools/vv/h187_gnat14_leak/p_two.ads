pragma Ada_2022;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
--  The form used by the H189 workaround in Different-Ways-To-Add-Parentheses-Lite:
--  one expression function (no separate declaration) carrying Ghost, Pre and
--  Subprogram_Variant.
package P_Two with SPARK_Mode => On is
   function W (N : Positive) return Big_Integer is
     (To_Big_Integer (case N is when 1 | 2 => 1, when 3 => 2, when 4 => 5, when others => 14));
   function Part (N : Positive; S : Natural) return Big_Integer is
     (if S = 0 then To_Big_Integer (0) else Part (N, S - 1) + W (S) * W (N - S))
   with Ghost, Pre => N in 2 .. 21 and then S < N, Subprogram_Variant => (Decreases => S);
end P_Two;
