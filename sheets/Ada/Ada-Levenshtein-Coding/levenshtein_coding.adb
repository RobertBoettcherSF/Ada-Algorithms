with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Levenshtein_Coding is

   function Encode (Value : Value_Type) return Bit_String is
      Result    : Unbounded_String := Null_Unbounded_String;
      N         : Value_Type := Value;
      C         : Natural := 1;
      M         : Natural;
      Temp_Bits : Unbounded_String;
      Temp      : Value_Type;
      Shifted   : Value_Type;
      Bit_Val   : Value_Type;
   begin
      -- Variant 1 Base Case: 0 is explicitly coded as "0"
      if Value = 0 then
         return (1 => B_0);
      end if;

      -- Iterate and prepend binary representations iteratively
      while N > 1 loop
         -- Step 1: Calculate M = floor(log2(N))
         M := 0;
         Temp := N;
         while Temp > 1 loop
            Temp := Temp / 2;
            M := M + 1;
         end loop;

         -- Step 2: Write the M bits of N (excluding leading 1) to Temp_Bits
         Temp_Bits := Null_Unbounded_String;
         Shifted := N;
         for I in 1 .. M loop
            Bit_Val := Shifted mod 2;
            Shifted := Shifted / 2;
            if Bit_Val = 0 then
               Temp_Bits := '0' & Temp_Bits;
            else
               Temp_Bits := '1' & Temp_Bits;
            end if;
         end loop;

         -- Step 3: Prepend the payload to our running result
         Result := Temp_Bits & Result;

         -- Step 4: Advance step count and repeat with M
         N := Value_Type (M);
         C := C + 1;
      end loop;

      -- Step 5: Write C '1' bits and a terminating '0' to the prefix
      Temp_Bits := To_Unbounded_String ("0");
      for I in 1 .. C loop
         Temp_Bits := '1' & Temp_Bits;
      end loop;

      Result := Temp_Bits & Result;

      return To_Bit_String (To_String (Result));
   end Encode;

   function Decode (Bits : Bit_String) return Value_Type is
      Str          : constant String := To_String (Bits);
      Idx          : Positive := Str'First;
      Count        : Natural := 0;
      N            : Value_Type;
      Val          : Value_Type;
      Bits_To_Read : Natural;
   begin
      -- Edge Case Validation
      if Str'Length = 0 then
         raise Invalid_Encoding with "Empty input string provided";
      end if;

      -- Step 1: Count leading '1' bits until a '0' is encountered
      while Idx <= Str'Last and then Str(Idx) = '1' loop
         Count := Count + 1;
         Idx := Idx + 1;
      end loop;

      -- Malformed Validation
      if Idx > Str'Last then
         raise Invalid_Encoding with "Missing terminating '0' in prefix";
      end if;
      
      if Str(Idx) /= '0' then
         raise Invalid_Encoding with "Expected '0' terminator after '1's";
      end if;
      Idx := Idx + 1; -- Discard the '0'

      -- Variant 2 Base Case Validation
      if Count = 0 then
         if Idx <= Str'Last then
            raise Invalid_Encoding with "Leftover extra bits after '0' payload";
         end if;
         return 0;
      end if;

      -- Step 2: Expand payload sequences sequentially
      N := 1;
      for Iter in 1 .. Count - 1 loop
         if N > Value_Type(Natural'Last) then
            raise Constraint_Error with "Value exceeded system Natural bounds";
         end if;
         
         Bits_To_Read := Natural (N);
         Val := 1; -- Start with a prepended '1'

         for J in 1 .. Bits_To_Read loop
            if Idx > Str'Last then
               raise Invalid_Encoding with "Incomplete payload encoding";
            end if;
            
            -- Arithmetic bound defense
            if Val > Value_Type'Last / 2 then
               raise Constraint_Error with "64-bit overflow during decode sequence";
            end if;
            
            Val := Val * 2;
            if Str(Idx) = '1' then
               Val := Val + 1;
            end if;
            Idx := Idx + 1;
         end loop;
         N := Val;
      end loop;

      -- Strict terminal bounds validation
      if Idx <= Str'Last then
         raise Invalid_Encoding with "Extraneous trailing bits found";
      end if;

      return N;
   end Decode;

   function To_String (Bits : Bit_String) return String is
      Str : String (1 .. Bits'Length);
   begin
      for I in Bits'Range loop
         if Bits (I) = B_0 then
            Str (I - Bits'First + 1) := '0';
         else
            Str (I - Bits'First + 1) := '1';
         end if;
      end loop;
      return Str;
   end To_String;

   function To_Bit_String (Str : String) return Bit_String is
      Bits : Bit_String (1 .. Str'Length);
   begin
      for I in Str'Range loop
         if Str (I) = '0' then
            Bits (I - Str'First + 1) := B_0;
         elsif Str (I) = '1' then
            Bits (I - Str'First + 1) := B_1;
         else
            raise Constraint_Error with "Invalid binary character inside string";
         end if;
      end loop;
      return Bits;
   end To_Bit_String;

end Levenshtein_Coding;
