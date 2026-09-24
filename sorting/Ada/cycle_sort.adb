--  Cycle_Sort body — classic write-optimal in-place cycle sort.

pragma Ada_2022;

package body Cycle_Sort
  with SPARK_Mode => Off
is

   procedure Check_Bounds (A : Element_Array) is
   begin
      if A'Length > Max_N then
         raise Invalid_Argument
           with "array length exceeds Max_N";
      end if;
   end Check_Bounds;

   --  Core cycle sort. Returns the number of array writes performed.
   --  Works for any A'First. Matches the Wikipedia Python/C++ outline:
   --  count strictly smaller elements to find destination; skip past
   --  equal duplicates; rotate the cycle with a held item.
   function Cycle_Sort_Core (A : in out Element_Array) return Natural is
      Writes : Natural := 0;
      Item   : Integer;
      Pos    : Natural;
      Tmp    : Integer;
   begin
      if A'Length <= 1 then
         return 0;
      end if;

      --  Last element is already in place after the first n-1 cycle starts.
      for Cycle_Start in A'First .. A'Last - 1 loop
         Item := A (Cycle_Start);

         --  Find where to put Item: count strictly smaller elements to
         --  the right of Cycle_Start (do not double-count the start).
         Pos := Cycle_Start;
         for I in Cycle_Start + 1 .. A'Last loop
            if A (I) < Item then
               Pos := Pos + 1;
            end if;
         end loop;

         --  Already in the correct position — not a cycle to rotate.
         if Pos /= Cycle_Start then
            --  Insert after any duplicates already at the destination.
            while Item = A (Pos) loop
               Pos := Pos + 1;
            end loop;

            Tmp     := A (Pos);
            A (Pos) := Item;
            Item    := Tmp;
            Writes  := Writes + 1;

            --  Rotate the rest of the cycle until back at Cycle_Start.
            while Pos /= Cycle_Start loop
               Pos := Cycle_Start;
               for I in Cycle_Start + 1 .. A'Last loop
                  if A (I) < Item then
                     Pos := Pos + 1;
                  end if;
               end loop;

               while Item = A (Pos) loop
                  Pos := Pos + 1;
               end loop;

               Tmp     := A (Pos);
               A (Pos) := Item;
               Item    := Tmp;
               Writes  := Writes + 1;
            end loop;
         end if;
      end loop;

      return Writes;
   end Cycle_Sort_Core;

   procedure Sort (A : in out Element_Array) is
      Writes : Natural;
   begin
      Check_Bounds (A);
      Writes := Cycle_Sort_Core (A);
      pragma Unreferenced (Writes);
   end Sort;

   function Sort_Counting_Writes (A : in out Element_Array) return Natural is
   begin
      Check_Bounds (A);
      return Cycle_Sort_Core (A);
   end Sort_Counting_Writes;

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

end Cycle_Sort;
