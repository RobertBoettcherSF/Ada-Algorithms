--  Bitonic_Sorter body — recursive BitonicSort / BitonicMerge with
--  optional power-of-two sentinel padding.

pragma Ada_2022;

package body Bitonic_Sorter
  with SPARK_Mode => Off
is

   procedure Check_Length (A : Element_Array) is
   begin
      if A'Length > Max_Length then
         raise Invalid_Argument
           with "array length exceeds Max_Length";
      end if;
   end Check_Length;

   function Is_Power_Of_Two (N : Natural) return Boolean is
      M : Natural := N;
   begin
      if N = 0 then
         return False;
      end if;
      while M > 1 loop
         if M rem 2 /= 0 then
            return False;
         end if;
         M := M / 2;
      end loop;
      return True;
   end Is_Power_Of_Two;

   function Next_Power_Of_Two (N : Natural) return Natural is
      P : Natural := 1;
   begin
      if N = 0 then
         return 1;
      end if;
      if Is_Power_Of_Two (N) then
         return N;
      end if;
      while P < N loop
         --  Powers of two up through at least 2^14 for Max_Length.
         P := P * 2;
      end loop;
      return P;
   end Next_Power_Of_Two;

   -------------------------------------------------------------------------
   -- Unchecked wire (trusted indices; used by the network)
   -------------------------------------------------------------------------

   procedure Wire_Compare_Swap
     (A         : in out Element_Array;
      I, J      : Natural;
      Ascending : Boolean)
   is
      T : Integer;
   begin
      if Ascending then
         if A (I) > A (J) then
            T := A (I);
            A (I) := A (J);
            A (J) := T;
         end if;
      else
         if A (I) < A (J) then
            T := A (I);
            A (I) := A (J);
            A (J) := T;
         end if;
      end if;
   end Wire_Compare_Swap;

   -------------------------------------------------------------------------
   -- Public compare-and-swap wire
   -------------------------------------------------------------------------

   procedure Compare_Swap
     (A         : in out Element_Array;
      I, J      : Natural;
      Ascending : Boolean)
   is
   begin
      Check_Length (A);
      if I not in A'Range or else J not in A'Range then
         raise Invalid_Argument
           with "Compare_Swap index out of range";
      end if;
      Wire_Compare_Swap (A, I, J, Ascending);
   end Compare_Swap;

   -------------------------------------------------------------------------
   -- Recursive network on a contiguous 0-based work buffer
   -------------------------------------------------------------------------

   --  Work arrays are always indexed 0 .. Len-1 so Low/Count arithmetic
   --  matches the Wikipedia pseudocode.

   procedure Bitonic_Merge
     (W         : in out Element_Array;
      Low       : Natural;
      Count     : Natural;
      Ascending : Boolean)
   is
      K : Natural;
   begin
      if Count <= 1 then
         return;
      end if;
      K := Count / 2;
      for I in Low .. Low + K - 1 loop
         Wire_Compare_Swap (W, I, I + K, Ascending);
      end loop;
      Bitonic_Merge (W, Low, K, Ascending);
      Bitonic_Merge (W, Low + K, K, Ascending);
   end Bitonic_Merge;

   procedure Bitonic_Sort
     (W         : in out Element_Array;
      Low       : Natural;
      Count     : Natural;
      Ascending : Boolean)
   is
      K : Natural;
   begin
      if Count <= 1 then
         return;
      end if;
      K := Count / 2;
      --  First half ascending, second half descending → bitonic sequence.
      Bitonic_Sort (W, Low, K, True);
      Bitonic_Sort (W, Low + K, K, False);
      Bitonic_Merge (W, Low, Count, Ascending);
   end Bitonic_Sort;

   -------------------------------------------------------------------------
   -- Public Sort (pad → network → trim)
   -------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array) is
      N : constant Natural := A'Length;
   begin
      Check_Length (A);
      if N <= 1 then
         return;
      end if;

      declare
         P : constant Natural := Next_Power_Of_Two (N);
         W : Element_Array (0 .. P - 1);
      begin
         for I in 0 .. N - 1 loop
            W (I) := A (A'First + I);
         end loop;
         --  Ascending sentinels: Integer'Last sorts to the high end and
         --  is discarded when trimming back to length N.
         for I in N .. P - 1 loop
            W (I) := Integer'Last;
         end loop;

         Bitonic_Sort (W, 0, P, True);

         for I in 0 .. N - 1 loop
            A (A'First + I) := W (I);
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

end Bitonic_Sorter;
