--  Spaghetti_Sort body — height-bin counting and max-extraction sims.

pragma Ada_2022;

package body Spaghetti_Sort
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

   -------------------------------------------------------------------------
   -- Height-bin / counting primary method (nonnegative bounded keys)
   -------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array) is
      --  Counts (H) = number of rods of length H.
      type Count_Array is array (0 .. Max_Key) of Natural;
      Counts : Count_Array := [others => 0];
   begin
      Check_Length (A);
      if A'Length <= 1 then
         return;
      end if;

      --  Validate keys and tally heights (prepare the rods).
      for I in A'Range loop
         declare
            K : constant Integer := A (I);
         begin
            if K < 0 or else K > Max_Key then
               raise Invalid_Argument
                 with "key outside 0 .. Max_Key for height-bin sort";
            end if;
            Counts (K) := Counts (K) + 1;
         end;
      end loop;

      --  Read bins from short to tall → ascending order.
      --  (Analog spaghetti extracts tallest-first / descending; we emit
      --  ascending so Sort matches the documented API contract.)
      declare
         Out_Index : Natural := A'First;
      begin
         for H in Counts'Range loop
            for C in 1 .. Counts (H) loop
               A (Out_Index) := H;
               Out_Index := Out_Index + 1;
            end loop;
         end loop;
      end;
   end Sort;

   -------------------------------------------------------------------------
   -- Max-extraction simulation for general Integers (O(n²))
   -------------------------------------------------------------------------

   procedure Sort_Extraction (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Length (A);
      if N <= 1 then
         return;
      end if;

      --  Extract maxima into descending order (prefer rightmost on ties so
      --  the final reverse yields a stable ascending order), then reverse.
      declare
         Desc : Element_Array (1 .. N);
         Used : array (A'Range) of Boolean := [others => False];
      begin
         for Step in 1 .. N loop
            declare
               Max_Index : Natural := A'First;
               Found     : Boolean := False;
            begin
               for I in A'Range loop
                  if not Used (I) then
                     if not Found then
                        Max_Index := I;
                        Found := True;
                     elsif A (I) >= A (Max_Index) then
                        Max_Index := I;
                     end if;
                  end if;
               end loop;
               Used (Max_Index) := True;
               Desc (Step) := A (Max_Index);
            end;
         end loop;

         for K in 1 .. N loop
            A (A'First + K - 1) := Desc (N - K + 1);
         end loop;
      end;
   end Sort_Extraction;

   -------------------------------------------------------------------------
   -- Predicate
   -------------------------------------------------------------------------

   function Is_Sorted (A : Element_Array) return Boolean is
   begin
      if A'Length <= 1 then
         return True;
      end if;
      for I in A'First .. A'Last - 1 loop
         if A (I) > A (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Sorted;

end Spaghetti_Sort;
