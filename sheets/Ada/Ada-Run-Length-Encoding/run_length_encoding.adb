with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Run_Length_Encoding is

   -- Helper to convert positive integers to strings without leading spaces
   function Trim_Image (Val : Positive) return String is
      Img : constant String := Positive'Image (Val);
   begin
      return Img (Img'First + 1 .. Img'Last);
   end Trim_Image;

   -------------------------------------------------------------------------
   -- Variant 1: String Encoding
   -------------------------------------------------------------------------
   function Encode_String (Input : String) return String is
      Result       : Unbounded_String := Null_Unbounded_String;
      Current_Char : Character;
      Count        : Positive := 1;
   begin
      if Input'Length = 0 then
         return "";
      end if;

      Current_Char := Input (Input'First);
      
      -- Validate first character
      if Current_Char in '0' .. '9' then
         raise Invalid_Format;
      end if;

      for I in Input'First + 1 .. Input'Last loop
         -- Refuse numeric digits in input to prevent decoding ambiguity
         if Input (I) in '0' .. '9' then
            raise Invalid_Format;
         end if;

         if Input (I) = Current_Char then
            Count := Count + 1;
         else
            Append (Result, Trim_Image (Count) & Current_Char);
            Current_Char := Input (I);
            Count := 1;
         end if;
      end loop;

      -- Append the final run
      Append (Result, Trim_Image (Count) & Current_Char);
      
      return To_String (Result);
   end Encode_String;

   function Decode_String (Input : String) return String is
      Result      : Unbounded_String := Null_Unbounded_String;
      I           : Integer := Input'First;
      Start_Digit : Integer;
      Count       : Positive;
      Char        : Character;
   begin
      if Input'Length = 0 then
         return "";
      end if;

      while I <= Input'Last loop
         Start_Digit := I;
         
         -- Consume digits
         while I <= Input'Last and then Input (I) in '0' .. '9' loop
            I := I + 1;
         end loop;

         -- Validate we found digits and they are followed by a character
         if I = Start_Digit or else I > Input'Last then
            raise Invalid_Format; 
         end if;

         begin
            Count := Positive'Value (Input (Start_Digit .. I - 1));
         exception
            when Constraint_Error => raise Invalid_Format; -- Count was 0 or invalid
         end;

         Char := Input (I);

         for J in 1 .. Count loop
            Append (Result, Char);
         end loop;

         I := I + 1;
      end loop;

      return To_String (Result);
   end Decode_String;

   -------------------------------------------------------------------------
   -- Variant 2: Binary Encoding
   -------------------------------------------------------------------------
   function Encode_Binary 
     (Input     : Binary_Array; 
      Start_Bit : out Boolean) return Count_Array 
   is
   begin
      if Input'Length = 0 then
         Start_Bit := False;
         return (1 .. 0 => 1); -- Return empty Count_Array
      end if;

      Start_Bit := Input (Input'First);

      declare
         Max_Counts  : Count_Array (1 .. Input'Length);
         Run_Count   : Natural := 0;
         Current_Bit : Boolean := Start_Bit;
         Count       : Positive := 1;
      begin
         for I in Input'First + 1 .. Input'Last loop
            if Input (I) = Current_Bit then
               Count := Count + 1;
            else
               Run_Count := Run_Count + 1;
               Max_Counts (Run_Count) := Count;
               Current_Bit := Input (I);
               Count := 1;
            end if;
         end loop;

         Run_Count := Run_Count + 1;
         Max_Counts (Run_Count) := Count;

         return Max_Counts (1 .. Run_Count);
      end;
   end Encode_Binary;

   function Decode_Binary 
     (Counts    : Count_Array; 
      Start_Bit : Boolean) return Binary_Array 
   is
      Total_Length : Natural := 0;
   begin
      for C of Counts loop
         Total_Length := Total_Length + C;
      end loop;

      declare
         Result      : Binary_Array (1 .. Total_Length);
         Current_Bit : Boolean := Start_Bit;
         Idx         : Positive := 1;
      begin
         for C of Counts loop
            for J in 1 .. C loop
               Result (Idx) := Current_Bit;
               Idx := Idx + 1;
            end loop;
            Current_Bit := not Current_Bit;
         end loop;
         return Result;
      end;
   end Decode_Binary;

end Run_Length_Encoding;
