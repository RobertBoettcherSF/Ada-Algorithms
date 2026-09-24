-- lz_compression.adb
-- Implementation body for LZ77 and LZ78

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body Lz_Compression is

   -----------------------------------------------------------------------------
   -- LZ77 Implementations
   -----------------------------------------------------------------------------
   
   function Lz77_Encode
     (Input          : String;
      Window_Size    : Positive := 255;
      Lookahead_Size : Positive := 15) return Lz77_Token_Array
   is
      Result      : Lz77_Token_Array (1 .. Input'Length);
      Token_Count : Natural := 0;
      Cursor      : Positive := Input'First;
   begin
      if Input'Length = 0 then
         raise Empty_Input_Error;
      end if;

      while Cursor <= Input'Last loop
         declare
            Best_Len    : Natural := 0;
            Best_Offset : Natural := 0;
            Max_Len     : constant Natural := Natural'Min (Lookahead_Size, Input'Last - Cursor);
            Limit       : Natural;
         begin
            -- Scan backward in the search window to find the longest matching sequence
            if Cursor > Input'First then
               Limit := Natural'Min (Cursor - Input'First, Window_Size);
               for I in 1 .. Limit loop
                  declare
                     Match_Len : Natural := 0;
                  begin
                     -- Expand match within lookahead bounds
                     while Match_Len < Max_Len and then
                       Input (Cursor - I + Match_Len) = Input (Cursor + Match_Len)
                     loop
                        Match_Len := Match_Len + 1;
                     end loop;
                     
                     -- Store if strictly better
                     if Match_Len > Best_Len then
                        Best_Len    := Match_Len;
                        Best_Offset := I;
                     end if;
                  end;
               end loop;
            end if;

            Token_Count := Token_Count + 1;
            Result (Token_Count).Offset := Best_Offset;
            Result (Token_Count).Length := Best_Len;

            -- Check if we've reached the very end of the string
            if Cursor + Best_Len <= Input'Last then
               Result (Token_Count).Next_Char := Input (Cursor + Best_Len);
               Result (Token_Count).Has_Next  := True;
               Cursor := Cursor + Best_Len + 1;
            else
               Result (Token_Count).Next_Char := ASCII.NUL;
               Result (Token_Count).Has_Next  := False;
               Cursor := Cursor + Best_Len;
            end if;
         end;
      end loop;

      return Result (1 .. Token_Count);
   end Lz77_Encode;


   function Lz77_Decode (Tokens : Lz77_Token_Array) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      if Tokens'Length = 0 then
         raise Empty_Input_Error;
      end if;

      for I in Tokens'Range loop
         -- Validate and reproduce the match from the window
         if Tokens (I).Length > 0 then
            if Tokens (I).Offset > Length (Result) then
               raise Invalid_Token_Error;
            end if;
            
            declare
               Start_Idx : constant Positive := Length (Result) - Tokens (I).Offset + 1;
            begin
               for J in 0 .. Tokens (I).Length - 1 loop
                  -- Note: LZ77 allows length > offset (overlapping copy)
                  Append (Result, Element (Result, Start_Idx + J));
               end loop;
            end;
         end if;
         
         -- Append trailing literal if available
         if Tokens (I).Has_Next then
            Append (Result, Tokens (I).Next_Char);
         end if;
      end loop;

      return To_String (Result);
   end Lz77_Decode;

   -----------------------------------------------------------------------------
   -- LZ78 Implementations
   -----------------------------------------------------------------------------
   
   type Dict_Node is record
      Prefix : Natural := 0;
      Char   : Character := ASCII.NUL;
   end record;
   type Dict_Array is array (Positive range <>) of Dict_Node;

   function Lz78_Encode
     (Input         : String;
      Max_Dict_Size : Positive := 4096) return Lz78_Token_Array
   is
      Dict          : Dict_Array (1 .. Max_Dict_Size);
      Dict_Size     : Natural := 0;
      Result        : Lz78_Token_Array (1 .. Input'Length);
      Token_Count   : Natural := 0;
      Current_Match : Natural := 0;
      Cursor        : Positive := Input'First;

      -- Helper to find a specific sequence within the dictionary
      function Find_Child (Parent : Natural; C : Character) return Natural is
      begin
         for I in 1 .. Dict_Size loop
            if Dict (I).Prefix = Parent and then Dict (I).Char = C then
               return I;
            end if;
         end loop;
         return 0;
      end Find_Child;

   begin
      if Input'Length = 0 then
         raise Empty_Input_Error;
      end if;

      while Cursor <= Input'Last loop
         declare
            Child : constant Natural := Find_Child (Current_Match, Input (Cursor));
         begin
            if Child > 0 then
               Current_Match := Child;
               
               -- Edge Case: if string ends exactly on a dictionary match
               if Cursor = Input'Last then
                  Token_Count := Token_Count + 1;
                  Result (Token_Count).Index    := Current_Match;
                  Result (Token_Count).Has_Next := False;
               end if;
               Cursor := Cursor + 1;
            else
               -- Record the token and clear the buffer
               Token_Count := Token_Count + 1;
               Result (Token_Count).Index     := Current_Match;
               Result (Token_Count).Next_Char := Input (Cursor);
               Result (Token_Count).Has_Next  := True;

               -- Store into dictionary if space permits
               if Dict_Size < Max_Dict_Size then
                  Dict_Size := Dict_Size + 1;
                  Dict (Dict_Size).Prefix := Current_Match;
                  Dict (Dict_Size).Char   := Input (Cursor);
               end if;

               Current_Match := 0;
               Cursor := Cursor + 1;
            end if;
         end;
      end loop;

      return Result (1 .. Token_Count);
   end Lz78_Encode;


   function Lz78_Decode (Tokens : Lz78_Token_Array) return String is
      -- Safe 4096 bound for LZ78 Dictionary reconstruction
      Dict      : Dict_Array (1 .. 4096);
      Dict_Size : Natural := 0;
      Result    : Unbounded_String := Null_Unbounded_String;

      -- Iterative function to follow node prefixes back to the root, preventing stack overflows
      function Reconstruct (Idx : Natural) return String is
         Temp_Str : Unbounded_String := Null_Unbounded_String;
         Current  : Natural := Idx;
         Rev_Str  : Unbounded_String := Null_Unbounded_String;
      begin
         while Current > 0 loop
            if Current > Dict_Size then 
               raise Invalid_Token_Error; 
            end if;
            Append (Temp_Str, Dict (Current).Char);
            Current := Dict (Current).Prefix;
         end loop;
         
         -- Strings resolve in reverse due to prefix pointer structures, invert here
         for I in reverse 1 .. Length (Temp_Str) loop
            Append (Rev_Str, Element (Temp_Str, I));
         end loop;
         return To_String (Rev_Str);
      end Reconstruct;

   begin
      if Tokens'Length = 0 then
         raise Empty_Input_Error;
      end if;

      for I in Tokens'Range loop
         declare
            Reconstructed : constant String := Reconstruct (Tokens (I).Index);
         begin
            Append (Result, Reconstructed);
            if Tokens (I).Has_Next then
               Append (Result, Tokens (I).Next_Char);
               
               -- Synchronize dictionary decoding exactly with the encoder
               if Dict_Size < Dict'Last then
                  Dict_Size := Dict_Size + 1;
                  Dict (Dict_Size).Prefix := Tokens (I).Index;
                  Dict (Dict_Size).Char   := Tokens (I).Next_Char;
               end if;
            end if;
         end;
      end loop;

      return To_String (Result);
   end Lz78_Decode;

end Lz_Compression;
