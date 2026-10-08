pragma Ada_2022;
package body LCS
  with SPARK_Mode => On
is
   type Row is array (0 .. Max_Len) of Natural;

   function Nat_Max (X, Y : Natural) return Natural
     with Global => null
   is
   begin
      if X >= Y then return X; else return Y; end if;
   end Nat_Max;

   function Length (A, B : Char_Array) return Natural is
      M : constant Len := A'Length;
      N : constant Len := B'Length;
      Prev : Row := [others => 0];
      Curr : Row := [others => 0];
   begin
      if M = 0 or else N = 0 then
         return 0;
      end if;
      for I in 1 .. M loop
         Curr (0) := 0;
         for J in 1 .. N loop
            if A (I) = B (J) then
               Curr (J) := Prev (J - 1) + 1;
            else
               Curr (J) := Nat_Max (Prev (J), Curr (J - 1));
            end if;
         end loop;
         for J in 0 .. N loop
            Prev (J) := Curr (J);
         end loop;
      end loop;
      return Prev (N);
   end Length;
end LCS;
