pragma Ada_2022;
package body Triangle_Min_Path with SPARK_Mode => On is
   function Minimum (T : Triangle) return Path_Sum is
      B41 : constant Natural := T (4, 1);
      B42 : constant Natural := T (4, 2);
      B43 : constant Natural := T (4, 3);
      B44 : constant Natural := T (4, 4);
      B31 : constant Natural := T (3, 1) + Natural'Min (B41, B42);
      B32 : constant Natural := T (3, 2) + Natural'Min (B42, B43);
      B33 : constant Natural := T (3, 3) + Natural'Min (B43, B44);
      B21 : constant Natural := T (2, 1) + Natural'Min (B31, B32);
      B22 : constant Natural := T (2, 2) + Natural'Min (B32, B33);
      B11 : constant Natural := T (1, 1) + Natural'Min (B21, B22);
   begin
      return Path_Sum (B11);
   end Minimum;
end Triangle_Min_Path;
