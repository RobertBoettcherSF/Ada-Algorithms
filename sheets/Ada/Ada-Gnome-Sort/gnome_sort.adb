--  Gnome_Sort body — classic gnome / stupid sort (garden-gnome swaps).
--  Advance when A(Pos) >= A(Pos-1) so equals keep relative order.

pragma Ada_2022;

package body Gnome_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      N   : constant Natural := A'Length;
      Pos : Natural;

      procedure Swap (I, J : Natural) is
         T : constant Integer := A (I);
      begin
         A (I) := A (J);
         A (J) := T;
      end Swap;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      --  Classic gnome: step forward when ordered (including equals via
      --  `>=`); otherwise swap with predecessor and step backward.
      Pos := A'First;
      while Pos <= A'Last loop
         if Pos = A'First or else A (Pos) >= A (Pos - 1) then
            Pos := Pos + 1;
         else
            Swap (Pos, Pos - 1);
            Pos := Pos - 1;
         end if;
      end loop;
   end Sort;

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First + 1 .. A'Last loop
         if A (I - 1) > A (I) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Gnome_Sort;
