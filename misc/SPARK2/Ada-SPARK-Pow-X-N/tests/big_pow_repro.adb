pragma Ada_2022;
--  Minimal reproducer for the Big_Integers "**" sign error (see
--  SOURCES.txt). The base is a variable, so Ada's precedence rule
--  (-2 ** 2 means -(2 ** 2)) plays no part. Not part of the build:
--    gnatmake -gnat2022 big_pow_repro.adb && ./big_pow_repro
--  GNAT 14.2 and 12.2 print FALSE twice; a fixed run-time prints TRUE.
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Big_Numbers.Big_Integers; use Ada.Numerics.Big_Numbers.Big_Integers;
procedure Big_Pow_Repro is
   Minus_Two    : constant Big_Integer := To_Big_Integer (-2);
   Minus_Three  : constant Big_Integer := To_Big_Integer (-3);
begin
   Put_Line ("V * V = " & To_String (Minus_Two * Minus_Two)
             & ", V ** 2 = " & To_String (Minus_Two ** 2) & " (V = -2)");
   Put_Line ("(-2) ** 2 = 4:  " & Boolean'Image (Minus_Two ** 2 = To_Big_Integer (4)));
   Put_Line ("(-3) ** 1 = -3: " & Boolean'Image (Minus_Three ** 1 = Minus_Three));
end Big_Pow_Repro;
