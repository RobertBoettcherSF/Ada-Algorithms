--  Pancake_Sorting body — prefix reversal and classic 2n − 3 sort.

pragma Ada_2022;

package body Pancake_Sorting
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
   -- Prefix reversal (1-based logical / document bounds)
   -------------------------------------------------------------------------

   procedure Flip (A : in out Element_Array; K : Natural) is
   begin
      Check_Length (A);
      if K > A'Length then
         raise Invalid_Argument
           with "prefix K exceeds array length";
      end if;
      if K <= 1 then
         return;
      end if;

      declare
         I : Natural := A'First;
         J : Natural := A'First + K - 1;
         T : Integer;
      begin
         while I < J loop
            T := A (I);
            A (I) := A (J);
            A (J) := T;
            I := I + 1;
            J := J - 1;
         end loop;
      end;
   end Flip;

   procedure Apply_Flips
     (A     : in out Element_Array;
      Flips : Flip_Sequence)
   is
   begin
      Check_Length (A);
      for K of Flips loop
         Flip (A, K);
      end loop;
   end Apply_Flips;

   -------------------------------------------------------------------------
   -- Classic pancake sort
   -------------------------------------------------------------------------

   procedure Pancake_Pass
     (A     : in out Element_Array;
      Flips : in out Flip_Sequence;
      Count : in out Natural;
      Store : Boolean)
   is
      N : constant Natural := A'Length;
   begin
      if N <= 1 then
         return;
      end if;

      for Size in reverse 2 .. N loop
         declare
            Lo     : constant Natural := A'First;
            Hi     : constant Natural := A'First + Size - 1;
            Max_At : Natural := Lo;
         begin
            --  Prefer the rightmost maximum so a nondecreasing prefix
            --  (including duplicate keys) is recognized as already placed.
            for I in Lo + 1 .. Hi loop
               if A (I) >= A (Max_At) then
                  Max_At := I;
               end if;
            end loop;

            if Max_At /= Hi then
               if Max_At /= Lo then
                  declare
                     K : constant Natural := Max_At - Lo + 1;
                  begin
                     Flip (A, K);
                     if Store then
                        if Count >= Flips'Length then
                           raise Invalid_Argument
                             with "flip sequence buffer too small";
                        end if;
                        Count := Count + 1;
                        Flips (Flips'First + Count - 1) := K;
                     end if;
                  end;
               end if;

               Flip (A, Size);
               if Store then
                  if Count >= Flips'Length then
                     raise Invalid_Argument
                       with "flip sequence buffer too small";
                  end if;
                  Count := Count + 1;
                  Flips (Flips'First + Count - 1) := Size;
               end if;
            end if;
         end;
      end loop;
   end Pancake_Pass;

   procedure Sort (A : in out Element_Array) is
      Dummy : Flip_Sequence (1 .. 0);
      Count : Natural := 0;
   begin
      Check_Length (A);
      Pancake_Pass (A, Dummy, Count, Store => False);
      pragma Unreferenced (Count);
   end Sort;

   procedure Sort
     (A     : in out Element_Array;
      Flips : out Flip_Sequence;
      Count : out Natural)
   is
      Buf : Flip_Sequence (Flips'Range) := [others => 0];
   begin
      Check_Length (A);
      Count := 0;
      Pancake_Pass (A, Buf, Count, Store => True);
      --  Copy recorded prefixes back; remaining slots of the out
      --  parameter are set to 0 so the whole array is written.
      for I in Flips'Range loop
         declare
            Off : constant Natural := I - Flips'First;
         begin
            if Off < Count then
               Flips (I) := Buf (Buf'First + Off);
            else
               Flips (I) := 0;
            end if;
         end;
      end loop;
   end Sort;

   -------------------------------------------------------------------------
   -- Predicate and bound
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

   function Classic_Flip_Bound (N : Natural) return Natural is
   begin
      if N <= 1 then
         return 0;
      else
         return 2 * N - 3;
      end if;
   end Classic_Flip_Bound;

end Pancake_Sorting;
