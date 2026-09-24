-- range_encoding.adb
-- Implementation of the Range Encoding algorithm.

package body Range_Encoding is

   -- =========================================================================
   -- Variant 1: Floating-Point Mathematical Encoding
   -- =========================================================================

   procedure Encode_Float (
      Input  : in  String;
      Model  : in  Float_Model_Array;
      Output : out Long_Float
   ) is
      Low   : Long_Float := 0.0;
      Range_Val : Long_Float := 1.0;
      Found : Boolean;
   begin
      if Input'Length = 0 then
         raise Encoding_Error with "Cannot encode empty string.";
      end if;

      for I in Input'Range loop
         Found := False;
         for M of Model loop
            if M.Sym = Input(I) then
               Low := Low + Range_Val * M.Cum_Prob;
               Range_Val := Range_Val * M.Prob;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            raise Encoding_Error with "Symbol not in model.";
         end if;
      end loop;
      
      -- Output the bottom of the final range
      Output := Low;
   end Encode_Float;


   procedure Decode_Float (
      Input  : in  Long_Float;
      Length : in  Positive;
      Model  : in  Float_Model_Array;
      Output : out String
   ) is
      Code  : Long_Float := Input;
      Found : Boolean;
   begin
      for I in 1 .. Length loop
         Found := False;
         for M in Model'Range loop
            -- Find the symbol range that contains 'Code'
            if Code >= Model(M).Cum_Prob and then 
               Code < Model(M).Cum_Prob + Model(M).Prob 
            then
               Output(Output'First + I - 1) := Model(M).Sym;
               Code := (Code - Model(M).Cum_Prob) / Model(M).Prob;
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            raise Decoding_Error with "Failed to decode valid symbol.";
         end if;
      end loop;
   end Decode_Float;

   -- =========================================================================
   -- Variant 2: Integer Arithmetic Encoding (Base 10)
   -- =========================================================================

   procedure Encode_Integer (
      Input      : in  String;
      Model      : in  Model_Array;
      Total_Freq : in  Positive;
      Output     : out Digit_Array;
      Out_Len    : out Natural
   ) is
      Low         : Unsigned_64 := 0;
      Range_Val   : Unsigned_64 := 100_000; -- Base 100,000 for 5 digits
      Base_Div    : constant Unsigned_64 := 10_000;
      Found       : Boolean;
      Range_Per_T : Unsigned_64;
   begin
      if Input'Length = 0 then
         raise Encoding_Error with "Cannot encode empty string.";
      end if;
      
      Out_Len := 0;

      for I in Input'Range loop
         Found := False;
         for M of Model loop
            if M.Sym = Input(I) then
               Range_Per_T := Range_Val / Unsigned_64(Total_Freq);
               Low := Low + Range_Per_T * Unsigned_64(M.Cum_Freq);
               Range_Val := Range_Per_T * Unsigned_64(M.Freq);
               Found := True;
               exit;
            end if;
         end loop;
         
         if not Found then
            raise Encoding_Error with "Symbol not in model.";
         end if;

         -- Normalization Loop
         while True loop
            if (Low / Base_Div) = ((Low + Range_Val - 1) / Base_Div) then
               -- First digits match, output the digit
               Out_Len := Out_Len + 1;
               if Out_Len > Output'Length then
                  raise Encoding_Error with "Output buffer too small";
               end if;
               Output(Output'First + Out_Len - 1) := Natural(Low / Base_Div);
               
               Low := (Low mod Base_Div) * 10;
               Range_Val := Range_Val * 10;
               
            elsif Range_Val < 1000 then
               -- Simplified underflow escape for edge cases
               Out_Len := Out_Len + 1;
               if Out_Len > Output'Length then
                  raise Encoding_Error with "Output buffer too small";
               end if;
               Output(Output'First + Out_Len - 1) := Natural(Low / Base_Div);
               
               Low := (Low mod Base_Div) * 10;
               Range_Val := Range_Val * 10;
            else
               exit;
            end if;
         end loop;
      end loop;
      
      -- Output remaining digits of Low to finish encoding cleanly
      declare
         Temp_Low : Unsigned_64 := Low;
      begin
         for K in 1 .. 5 loop
            Out_Len := Out_Len + 1;
            if Out_Len > Output'Length then
               raise Encoding_Error with "Output buffer too small";
            end if;
            Output(Output'First + Out_Len - 1) := Natural(Temp_Low / Base_Div);
            Temp_Low := (Temp_Low mod Base_Div) * 10;
         end loop;
      end;
      
   end Encode_Integer;


   procedure Decode_Integer (
      Input      : in  Digit_Array;
      Length     : in  Positive;
      Model      : in  Model_Array;
      Total_Freq : in  Positive;
      Output     : out String
   ) is
      Low         : Unsigned_64 := 0;
      Range_Val   : Unsigned_64 := 100_000;
      Code        : Unsigned_64 := 0;
      Base_Div    : constant Unsigned_64 := 10_000;
      Range_Per_T : Unsigned_64;
      Value       : Unsigned_64;
      Found       : Boolean;
      In_Idx      : Natural := Input'First;
   begin
      -- Load initial 5 digits into Code
      for I in 1 .. 5 loop
         Code := Code * 10 + (if In_Idx <= Input'Last then Unsigned_64(Input(In_Idx)) else 0);
         In_Idx := In_Idx + 1;
      end loop;

      for I in 1 .. Length loop
         Range_Per_T := Range_Val / Unsigned_64(Total_Freq);
         Value := (Code - Low) / Range_Per_T;
         
         Found := False;
         for M in Model'Range loop
            if Value >= Unsigned_64(Model(M).Cum_Freq) and then 
               Value < Unsigned_64(Model(M).Cum_Freq + Model(M).Freq) 
            then
               Output(Output'First + I - 1) := Model(M).Sym;
               Low := Low + Range_Per_T * Unsigned_64(Model(M).Cum_Freq);
               Range_Val := Range_Per_T * Unsigned_64(Model(M).Freq);
               Found := True;
               exit;
            end if;
         end loop;
         
         if not Found then
            raise Decoding_Error with "Failed to decode symbol.";
         end if;
         
         -- Normalization Loop
         while True loop
            if (Low / Base_Div) = ((Low + Range_Val - 1) / Base_Div) then
               Low := (Low mod Base_Div) * 10;
               Range_Val := Range_Val * 10;
               Code := (Code mod Base_Div) * 10 + (if In_Idx <= Input'Last then Unsigned_64(Input(In_Idx)) else 0);
               In_Idx := In_Idx + 1;
            elsif Range_Val < 1000 then
               Low := (Low mod Base_Div) * 10;
               Range_Val := Range_Val * 10;
               Code := (Code mod Base_Div) * 10 + (if In_Idx <= Input'Last then Unsigned_64(Input(In_Idx)) else 0);
               In_Idx := In_Idx + 1;
            else
               exit;
            end if;
         end loop;
      end loop;
   end Decode_Integer;

end Range_Encoding;
