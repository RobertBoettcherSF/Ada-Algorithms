package body Xor_Swap_Algorithm is

   ----------------------------------------------------------------------------
   -- Standard Swap: X = X ^ Y, Y = X ^ Y, X = X ^ Y
   ----------------------------------------------------------------------------
   procedure Swap (X, Y : in out Data_Type) is
   begin
      X := X xor Y;
      Y := X xor Y;
      X := X xor Y;
   end Swap;

   ----------------------------------------------------------------------------
   -- Safe Swap Elements: Prevents Aliasing Zero-Out
   ----------------------------------------------------------------------------
   procedure Swap_Elements (Arr : in out Data_Array; I, J : Natural) is
   begin
      -- Ensure we are not operating on the exact same memory location
      if I /= J then
         Arr (I) := Arr (I) xor Arr (J);
         Arr (J) := Arr (I) xor Arr (J);
         Arr (I) := Arr (I) xor Arr (J);
      end if;
      -- If I = J, doing nothing prevents the value from becoming 0.
   end Swap_Elements;

   ----------------------------------------------------------------------------
   -- Array Reversal: Two-pointer approach with XOR Swap
   ----------------------------------------------------------------------------
   procedure Reverse_Array (Arr : in out Data_Array) is
      Left  : Natural := Arr'First;
      Right : Natural := Arr'Last;
   begin
      -- Edge case: Empty or single element arrays require no reversal
      if Arr'Length <= 1 then
         return;
      end if;

      while Left < Right loop
         Swap_Elements (Arr, Left, Right);
         Left := Left + 1;
         Right := Right - 1;
      end loop;
   end Reverse_Array;

end Xor_Swap_Algorithm;
