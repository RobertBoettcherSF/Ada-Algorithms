pragma Ada_2022;
package body Longest_Common_Substring
  with SPARK_Mode => On
is
   type DP_Row is array (Idx) of Natural;

   function Length (A, B : Char_Array) return Natural is
      M : constant Len := A'Length;
      N : constant Len := B'Length;
      Prev : DP_Row := [others => 0];
      Curr : DP_Row := [others => 0];
      Best : Natural := 0;
   begin
      if M = 0 or else N = 0 then return 0; end if;
      for I in 1 .. M loop
         Curr (0) := 0;
         for J in 1 .. N loop
            if A (I) = B (J) then
               Curr (J) := Prev (J - 1) + 1;
               if Curr (J) > Best then Best := Curr (J); end if;
            else
               Curr (J) := 0;
            end if;
         end loop;
         for J in 0 .. N loop
            Prev (J) := Curr (J);
         end loop;
      end loop;
      return Best;
   end Length;
end Longest_Common_Substring;
