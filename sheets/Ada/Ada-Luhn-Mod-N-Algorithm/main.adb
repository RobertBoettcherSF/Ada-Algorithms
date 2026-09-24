-- main.adb
-- Demonstration of the Luhn Mod N package

with Ada.Text_IO; use Ada.Text_IO;
with Luhn_Mod_N;  use Luhn_Mod_N;

procedure Main is
   Num_Codec : Codec;
   Original  : constant String := "7992739871";
   Result    : String (1 .. Original'Length + 1);
begin
   Put_Line("=== Luhn Mod N Algorithm Demo ===");
   Num_Codec := Create_Codec("0123456789");
   
   Result := Append_Check_Character(Num_Codec, Original);
   Put_Line("Original Input : " & Original);
   Put_Line("With Check Char: " & Result);
   
   if Validate(Num_Codec, Result) then
      Put_Line("Validation: SUCCESS");
   else
      Put_Line("Validation: FAILED");
   end if;
end Main;
