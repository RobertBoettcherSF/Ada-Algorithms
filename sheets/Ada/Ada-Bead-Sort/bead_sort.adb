--  Bead_Sort body — drop beads on rods, read gravity levels ascending.

pragma Ada_2022;

package body Bead_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
      for I in A'Range loop
         if A (I) > Max_Value then
            raise Invalid_Argument
              with "element exceeds Max_Value";
         end if;
      end loop;
   end Check_Bounds;

   procedure Sort (A : in out Element_Array) is
      Max_Val : Natural := 0;
      N       : constant Natural := A'Length;
   begin
      Check_Bounds (A);

      if N <= 1 then
         return;
      end if;

      for I in A'Range loop
         if A (I) > Max_Val then
            Max_Val := A (I);
         end if;
      end loop;

      --  All zeros: already sorted.
      if Max_Val = 0 then
         return;
      end if;

      declare
         subtype Rod_Index is Positive range 1 .. Max_Val;
         Rods : array (Rod_Index) of Natural := [others => 0];
         Idx  : Natural := A'First;
         Count : Natural;
      begin
         --  Drop a_i beads onto rods 1 .. a_i (column counts = gravity).
         for I in A'Range loop
            if A (I) > 0 then
               for J in 1 .. A (I) loop
                  Rods (J) := Rods (J) + 1;
               end loop;
            end if;
         end loop;

         --  Read rows from top (H = N) to bottom (H = 1): few beads →
         --  small values first (ascending). Row H has a bead on rod J
         --  iff Rods(J) >= H; the row's value is that bead count.
         for H in reverse 1 .. N loop
            Count := 0;
            for J in Rods'Range loop
               if Rods (J) >= H then
                  Count := Count + 1;
               end if;
            end loop;
            A (Idx) := Count;
            Idx := Idx + 1;
         end loop;
      end;
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

end Bead_Sort;
