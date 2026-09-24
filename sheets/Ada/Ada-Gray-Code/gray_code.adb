package body Gray_Code is

   -- =========================================================================
   -- 1. Standard Binary Reflected Gray Code (BRGC) for Integers
   -- =========================================================================

   function Binary_To_Gray (Value : Word) return Word is
   begin
      -- Division by 2 acts as an unsigned right shift for modular types.
      return Value xor (Value / 2);
   end Binary_To_Gray;

   function Gray_To_Binary (Value : Word) return Word is
      Result : Word := Value;
      Mask   : Word := Value;
   begin
      Mask := Mask / 2;
      while Mask /= 0 loop
         Result := Result xor Mask;
         Mask   := Mask / 2;
      end loop;
      return Result;
   end Gray_To_Binary;

   -- =========================================================================
   -- 2. String Representations of BRGC
   -- =========================================================================

   function Binary_String_To_Gray (Binary_Str : String) return String is
      Result : String (Binary_Str'Range);
      Prev   : Character := '0';
   begin
      if Binary_Str'Length = 0 then
         raise Empty_Constraint;
      end if;

      for I in Binary_Str'Range loop
         if Binary_Str (I) /= '0' and then Binary_Str (I) /= '1' then
            raise Invalid_String;
         end if;

         -- XOR equivalent for characters: 
         -- '1' if current bit differs from previous bit, else '0'
         if Binary_Str (I) = Prev then
            Result (I) := '0';
         else
            Result (I) := '1';
         end if;
         Prev := Binary_Str (I);
      end loop;

      return Result;
   end Binary_String_To_Gray;

   function Gray_String_To_Binary (Gray_Str : String) return String is
      Result : String (Gray_Str'Range);
      Prev   : Character := '0';
   begin
      if Gray_Str'Length = 0 then
         raise Empty_Constraint;
      end if;

      for I in Gray_Str'Range loop
         if Gray_Str (I) /= '0' and then Gray_Str (I) /= '1' then
            raise Invalid_String;
         end if;

         if Gray_Str (I) = '1' then
            if Prev = '0' then 
               Prev := '1'; 
            else 
               Prev := '0'; 
            end if;
         end if;
         Result (I) := Prev;
      end loop;

      return Result;
   end Gray_String_To_Binary;

   -- =========================================================================
   -- 3. Sequence Generation and Validation
   -- =========================================================================

   function Generate_BRGC (Bits : Bit_Count) return Word_Array is
      Total  : constant Natural := 2**Bits;
      Result : Word_Array (1 .. Total);
   begin
      for I in 0 .. Total - 1 loop
         Result (I + 1) := Binary_To_Gray (Word (I));
      end loop;
      return Result;
   end Generate_BRGC;

   function Is_Valid_Gray_Sequence (Seq : Word_Array) return Boolean is
      Diff : Word;
   begin
      if Seq'Length < 2 then
         return True;
      end if;

      for I in Seq'First .. Seq'Last - 1 loop
         Diff := Seq (I) xor Seq (I + 1);
         -- In a valid binary Gray code, adjacent values differ by exactly one bit.
         -- Checking if Diff is a power of 2 confirms exactly one bit is set.
         if Diff = 0 or else (Diff and (Diff - 1)) /= 0 then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Gray_Sequence;

   -- =========================================================================
   -- 4. N-Ary Gray Code (Non-Boolean)
   -- =========================================================================
   -- Based on standard non-Boolean Gray Code logic:
   -- g_i = d_i if the sum of all higher-order digits is even.
   -- g_i = (Base - 1) - d_i if the sum of all higher-order digits is odd.

   function N_Ary_To_Gray (Values : Digit_Array; Base : Base_Type) return Digit_Array is
      Result : Digit_Array (Values'Range);
      Shift  : Natural := 0;
   begin
      if Values'Length = 0 then
         raise Empty_Constraint;
      end if;

      for I in Values'Range loop
         if Natural (Values (I)) >= Base then
            raise Invalid_Digit;
         end if;

         if Shift mod 2 = 0 then
            Result (I) := Values (I);
         else
            Result (I) := Digit_Type (Base - 1) - Values (I);
         end if;

         -- Accumulate sum of higher order digits (assuming index 1 is Most Significant)
         Shift := Shift + Natural (Values (I));
      end loop;

      return Result;
   end N_Ary_To_Gray;

   function Gray_To_N_Ary (Values : Digit_Array; Base : Base_Type) return Digit_Array is
      Result : Digit_Array (Values'Range);
      Shift  : Natural := 0;
   begin
      if Values'Length = 0 then
         raise Empty_Constraint;
      end if;

      for I in Values'Range loop
         if Natural (Values (I)) >= Base then
            raise Invalid_Digit;
         end if;

         if Shift mod 2 = 0 then
            Result (I) := Values (I);
         else
            Result (I) := Digit_Type (Base - 1) - Values (I);
         end if;

         -- Accumulate sum using the *decoded* standard base digit
         Shift := Shift + Natural (Result (I));
      end loop;

      return Result;
   end Gray_To_N_Ary;

end Gray_Code;
