with Detect_Capital;
procedure Tests is
   Upper : constant Detect_Capital.Text_Array := "USAABC";
   Lower : constant Detect_Capital.Text_Array := "foobar";
   Title : constant Detect_Capital.Text_Array := "Google";
   Mixed : constant Detect_Capital.Text_Array := "FlaGge";
begin
   pragma Assert (Detect_Capital.Is_Correct (Upper));
   pragma Assert (Detect_Capital.Is_Correct (Lower));
   pragma Assert (Detect_Capital.Is_Correct (Title));
   pragma Assert (not Detect_Capital.Is_Correct (Mixed));
end Tests;
