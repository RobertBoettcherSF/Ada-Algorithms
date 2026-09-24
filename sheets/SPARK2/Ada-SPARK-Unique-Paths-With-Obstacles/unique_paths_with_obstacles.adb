pragma Ada_2022;
package body Unique_Paths_With_Obstacles with SPARK_Mode => On is
   function Count (G : Grid) return Path_Count is
      A11 : constant Natural := (if G (1, 1) then 0 else 1);
      A12 : constant Natural := (if G (1, 2) then 0 else A11);
      A13 : constant Natural := (if G (1, 3) then 0 else A12);
      A14 : constant Natural := (if G (1, 4) then 0 else A13);
      A21 : constant Natural := (if G (2, 1) then 0 else A11);
      A22 : constant Natural := (if G (2, 2) then 0 else A12 + A21);
      A23 : constant Natural := (if G (2, 3) then 0 else A13 + A22);
      A24 : constant Natural := (if G (2, 4) then 0 else A14 + A23);
      A31 : constant Natural := (if G (3, 1) then 0 else A21);
      A32 : constant Natural := (if G (3, 2) then 0 else A22 + A31);
      A33 : constant Natural := (if G (3, 3) then 0 else A23 + A32);
      A34 : constant Natural := (if G (3, 4) then 0 else A24 + A33);
      A41 : constant Natural := (if G (4, 1) then 0 else A31);
      A42 : constant Natural := (if G (4, 2) then 0 else A32 + A41);
      A43 : constant Natural := (if G (4, 3) then 0 else A33 + A42);
      A44 : constant Natural := (if G (4, 4) then 0 else A34 + A43);
   begin
      return Path_Count (A44);
   end Count;
end Unique_Paths_With_Obstacles;
