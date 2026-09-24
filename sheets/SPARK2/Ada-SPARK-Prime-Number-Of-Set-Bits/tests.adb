with Prime_Number_Of_Set_Bits; use Prime_Number_Of_Set_Bits;
procedure Tests is
begin
   pragma Assert (Is_Prime_Count (2));
   pragma Assert (Is_Prime_Count (7));
   pragma Assert (not Is_Prime_Count (4));
end Tests;
