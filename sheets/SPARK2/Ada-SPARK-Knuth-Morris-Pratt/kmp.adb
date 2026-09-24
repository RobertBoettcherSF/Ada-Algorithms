pragma Ada_2022;
package body KMP
  with SPARK_Mode => On
is
   procedure Build_Prefix (Pat : Char_Array; Pi : out Prefix_Table) is
      Len : Natural := 0;
      I   : Positive := 2;
   begin
      Pi := [others => 0];
      Pi (1) := 0;
      while I <= Pat'Last loop
         pragma Loop_Invariant (I in 2 .. Pat'Last + 1);
         pragma Loop_Invariant (Len < I);
         if Pat (I) = Pat (Len + 1) then
            Len := Len + 1;
            Pi (I) := Len;
            I := I + 1;
         elsif Len /= 0 then
            Len := Pi (Len);
         else
            Pi (I) := 0;
            I := I + 1;
         end if;
      end loop;
   end Build_Prefix;
end KMP;
