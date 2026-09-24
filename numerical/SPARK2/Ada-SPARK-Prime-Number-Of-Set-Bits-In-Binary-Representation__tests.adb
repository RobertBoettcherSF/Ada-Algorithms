pragma Ada_2022;
with Prime_Number_Of_Set_Bits_In_Binary_Representation;
procedure Tests is
   package P renames Prime_Number_Of_Set_Bits_In_Binary_Representation;
begin
   pragma Assert (not P.Has_Prime_Set_Bit_Count (0));
   pragma Assert (P.Has_Prime_Set_Bit_Count (3));
   pragma Assert (P.Has_Prime_Set_Bit_Count (7));
   pragma Assert (not P.Has_Prime_Set_Bit_Count (16#F#));
end Tests;
