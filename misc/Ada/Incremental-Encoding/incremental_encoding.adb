package body Incremental_Encoding is

   ------------------------------------------------------------------
   -- Helper Function: Calculate common prefix length of two strings
   ------------------------------------------------------------------
   function Common_Prefix_Length (Str1, Str2 : Unbounded_String) return Natural is
      Len1 : constant Natural := Length (Str1);
      Len2 : constant Natural := Length (Str2);
      Min_Len : constant Natural := Natural'Min (Len1, Len2);
      Count : Natural := 0;
   begin
      for I in 1 .. Min_Len loop
         if Element (Str1, I) = Element (Str2, I) then
            Count := Count + 1;
         else
            exit;
         end if;
      end loop;
      return Count;
   end Common_Prefix_Length;


   ------------------------------------------------------------------
   -- Encode: Compresses an array of strings using Incremental Encoding
   ------------------------------------------------------------------
   function Encode (Input : String_Array) return Encoded_Array is
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot encode an empty array.";
      end if;

      declare
         Result : Encoded_Array (1 .. Input'Length);
         Input_Idx : Positive := Input'First;
         Prefix_Len : Natural;
      begin
         -- First element always has prefix 0
         Result (1) := (Prefix_Length => 0, Suffix => Input (Input_Idx));
         
         -- Iterate and encode remaining elements based on their predecessor
         for I in 2 .. Result'Last loop
            Input_Idx := Input_Idx + 1;
            Prefix_Len := Common_Prefix_Length (Input (Input_Idx - 1), Input (Input_Idx));
            
            Result (I) := (
               Prefix_Length => Prefix_Len,
               Suffix => Unbounded_Slice (Input (Input_Idx), Prefix_Len + 1, Length (Input (Input_Idx)))
            );
         end loop;
         
         return Result;
      end;
   end Encode;


   ------------------------------------------------------------------
   -- Decode: Reconstructs original strings from Encoded Array
   ------------------------------------------------------------------
   function Decode (Input : Encoded_Array) return String_Array is
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error with "Cannot decode an empty array.";
      end if;
      
      -- Validate that the first element has no prefix dependency
      if Input (Input'First).Prefix_Length /= 0 then
         raise Invalid_Data_Error with "First encoded element must have Prefix_Length 0.";
      end if;

      declare
         Result : String_Array (1 .. Input'Length);
         Input_Idx : Positive := Input'First;
         Prev_Str : Unbounded_String;
      begin
         -- Base case: first element
         Result (1) := Input (Input_Idx).Suffix;
         Prev_Str := Result (1);
         
         -- Reconstruct remaining elements
         for I in 2 .. Result'Last loop
            Input_Idx := Input_Idx + 1;
            
            -- Validation check to prevent out of bounds reading
            if Input (Input_Idx).Prefix_Length > Length (Prev_Str) then
               raise Invalid_Data_Error with "Prefix length exceeds previous string length.";
            end if;
            
            Result (I) := Unbounded_Slice (Prev_Str, 1, Input (Input_Idx).Prefix_Length) & Input (Input_Idx).Suffix;
            Prev_Str := Result (I);
         end loop;
         
         return Result;
      end;
   end Decode;

end Incremental_Encoding;
