-- dictionary_coder.adb
-- Implementation body for the Dictionary Coder package.

package body Dictionary_Coder is

   -------------------------------------------------------------------------
   -- Static Dictionary Implementations
   -------------------------------------------------------------------------

   procedure Add_To_Dictionary (Dict : in out Static_Dictionary; Word : String) is
   begin
      if Word = "" then
         raise Dictionary_Error with "Cannot add empty word to static dictionary.";
      end if;

      if not Dict.Encoder_Map.Contains (Word) then
         Dict.Encoder_Map.Insert (Word, Dict.Next_Code);
         Dict.Decoder_Map.Insert (Dict.Next_Code, Word);
         Dict.Next_Code := Dict.Next_Code + 1;
      end if;
   end Add_To_Dictionary;

   function Encode_Static (Dict : Static_Dictionary; Text : String) return Code_Array is
      -- Safe upper bound: max number of words cannot exceed string length
      Result    : Code_Array (1 .. Text'Length);
      Count     : Natural := 0;
      Start_Idx : Positive := Text'First;
      In_Word   : Boolean := False;
   begin
      -- Edge case: Empty input
      if Text = "" then
         return Result (1 .. 0);
      end if;

      -- Iterate and extract space-separated words
      for I in Text'Range loop
         if Text(I) /= ' ' then
            if not In_Word then
               Start_Idx := I;
               In_Word := True;
            end if;
            
            -- End of string while inside a word
            if I = Text'Last then
               Count := Count + 1;
               declare
                  W : constant String := Text (Start_Idx .. I);
               begin
                  if not Dict.Encoder_Map.Contains (W) then
                     raise Encode_Error with "Word not found in static dict: " & W;
                  end if;
                  Result(Count) := Dict.Encoder_Map.Element (W);
               end;
            end if;
         else
            -- Space encountered, process previous word
            if In_Word then
               Count := Count + 1;
               declare
                  W : constant String := Text (Start_Idx .. I - 1);
               begin
                  if not Dict.Encoder_Map.Contains (W) then
                     raise Encode_Error with "Word not found in static dict: " & W;
                  end if;
                  Result(Count) := Dict.Encoder_Map.Element (W);
               end;
               In_Word := False;
            end if;
         end if;
      end loop;
      
      return Result (1 .. Count);
   end Encode_Static;

   function Decode_Static (Dict : Static_Dictionary; Codes : Code_Array) return String is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      -- Edge case: Empty input array
      if Codes'Length = 0 then
         return "";
      end if;

      for I in Codes'Range loop
         if not Dict.Decoder_Map.Contains (Codes(I)) then
            raise Decode_Error with "Invalid code encountered in static decode.";
         end if;
         
         Append (Result, Dict.Decoder_Map.Element (Codes(I)));
         
         if I /= Codes'Last then
            Append (Result, " ");
         end if;
      end loop;
      
      return To_String (Result);
   end Decode_Static;


   -------------------------------------------------------------------------
   -- Dynamic Dictionary Implementations (LZW)
   -------------------------------------------------------------------------

   function LZW_Encode (Text : String) return Code_Array is
      Dict      : String_Code_Maps.Map;
      Next_Code : Code_Type := 256;
      W         : Unbounded_String := Null_Unbounded_String;
      Res_Array : Code_Array (1 .. Text'Length); 
      Count     : Natural := 0;
   begin
      -- Edge case: Empty input
      if Text = "" then
         return Res_Array (1 .. 0);
      end if;

      -- Initialize dictionary with all 256 single-character strings
      for I in 0 .. 255 loop
         Dict.Insert ( (1 => Character'Val(I)), Code_Type(I) );
      end loop;

      -- LZW Algorithm Core Logic
      for I in Text'Range loop
         declare
            K  : constant Character := Text(I);
            WK : constant String := To_String(W) & K;
         begin
            if Dict.Contains (WK) then
               W := To_Unbounded_String(WK);
            else
               Count := Count + 1;
               Res_Array(Count) := Dict.Element (To_String(W));
               
               -- Add WK to dictionary
               Dict.Insert (WK, Next_Code);
               Next_Code := Next_Code + 1;
               
               -- Reset W to K
               W := To_Unbounded_String((1 => K));
            end if;
         end;
      end loop;
      
      -- Output the code for the remaining string W
      if Length(W) > 0 then
         Count := Count + 1;
         Res_Array(Count) := Dict.Element (To_String(W));
      end if;
      
      return Res_Array (1 .. Count);
   end LZW_Encode;


   function LZW_Decode (Codes : Code_Array) return String is
      Dict      : Code_String_Maps.Map;
      Next_Code : Code_Type := 256;
      Old_Code  : Code_Type;
      New_Code  : Code_Type;
      S         : Unbounded_String;
      C         : Character;
      Result    : Unbounded_String := Null_Unbounded_String;
   begin
      -- Edge case: Empty array
      if Codes'Length = 0 then
         return "";
      end if;

      -- Initialize dictionary with 256 single-character strings
      for I in 0 .. 255 loop
         Dict.Insert ( Code_Type(I), (1 => Character'Val(I)) );
      end loop;

      Old_Code := Codes(Codes'First);
      
      if not Dict.Contains(Old_Code) then
         raise Decode_Error with "Invalid first LZW code.";
      end if;
      
      S := To_Unbounded_String(Dict.Element(Old_Code));
      C := Element(S, 1);
      Append (Result, S);

      -- LZW Decode Loop
      for I in Codes'First + 1 .. Codes'Last loop
         New_Code := Codes(I);
         
         if Dict.Contains(New_Code) then
            -- Standard case: Code exists in dictionary
            S := To_Unbounded_String(Dict.Element(New_Code));
         elsif New_Code = Next_Code then
            -- Edge case (cScSc): Code does not exist yet; use previous string + its first char
            S := To_Unbounded_String(Dict.Element(Old_Code) & C);
         else
            raise Decode_Error with "Malformed LZW sequence (unknown future code).";
         end if;
         
         Append (Result, S);
         C := Element(S, 1);
         
         -- Add new string to dictionary
         Dict.Insert (Next_Code, Dict.Element(Old_Code) & C);
         Next_Code := Next_Code + 1;
         Old_Code := New_Code;
      end loop;
      
      return To_String(Result);
   end LZW_Decode;

end Dictionary_Coder;
