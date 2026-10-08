pragma Ada_2022;
package body KMP
  with SPARK_Mode => On
is
   procedure Build_Prefix (Pat : Char_Array; Pi : out Prefix_Table) is
      N   : constant Positive := Pat'Length;
      P0  : constant Natural := Pat'First - 1;
      Q0  : constant Natural := Pi'First - 1;
      Len : Natural := 0;
      I   : Positive := 2;
   begin
      Pi := [others => 0];
      while I <= N loop
         pragma Loop_Invariant (I in 2 .. N + 1);
         pragma Loop_Invariant (Len < I - 1);
         pragma Loop_Invariant
           (for all J in Pi'Range => Pi (J) < J - Q0);
         pragma Loop_Variant (Increases => 2 * I - Len);
         if Pat (P0 + I) = Pat (P0 + Len + 1) then
            pragma Assert (Len + 1 < I);
            Len := Len + 1;
            Pi (Q0 + I) := Len;
            I := I + 1;
         elsif Len /= 0 then
            pragma Assert (Len in 1 .. N and then Pi (Q0 + Len) < Len);
            Len := Pi (Q0 + Len);
         else
            Pi (Q0 + I) := 0;
            I := I + 1;
         end if;
      end loop;
   end Build_Prefix;
end KMP;
