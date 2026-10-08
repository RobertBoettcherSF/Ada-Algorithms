pragma Ada_2022;
package body Minimum_Path_Sum with SPARK_Mode => On is
   function Minimum (G : Grid) return Path_Sum is
      A11 : constant Natural := G (1, 1);
      A12 : constant Natural := G (1, 2) + A11;
      A13 : constant Natural := G (1, 3) + A12;
      A14 : constant Natural := G (1, 4) + A13;
      A21 : constant Natural := G (2, 1) + A11;
      A22 : constant Natural := G (2, 2) + Natural'Min (A12, A21);
      A23 : constant Natural := G (2, 3) + Natural'Min (A13, A22);
      A24 : constant Natural := G (2, 4) + Natural'Min (A14, A23);
      A31 : constant Natural := G (3, 1) + A21;
      A32 : constant Natural := G (3, 2) + Natural'Min (A22, A31);
      A33 : constant Natural := G (3, 3) + Natural'Min (A23, A32);
      A34 : constant Natural := G (3, 4) + Natural'Min (A24, A33);
      A41 : constant Natural := G (4, 1) + A31;
      A42 : constant Natural := G (4, 2) + Natural'Min (A32, A41);
      A43 : constant Natural := G (4, 3) + Natural'Min (A33, A42);
      A44 : constant Natural := G (4, 4) + Natural'Min (A34, A43);
   begin
      return Path_Sum (A44);
   end Minimum;
end Minimum_Path_Sum;
