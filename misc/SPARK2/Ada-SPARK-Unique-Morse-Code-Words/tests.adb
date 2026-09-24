with Unique_Morse_Code_Words;
procedure Tests is
   Unique : constant Unique_Morse_Code_Words.Code_Array := [1, 2, 4, 8];
   Repeat : constant Unique_Morse_Code_Words.Code_Array := [1, 2, 1, 8];
begin
   pragma Assert (Unique_Morse_Code_Words.All_Unique (Unique));
   pragma Assert (not Unique_Morse_Code_Words.All_Unique (Repeat));
end Tests;
