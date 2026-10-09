with Ada.Assertions; use Ada.Assertions;
with Defanging_IP; use Defanging_IP;
with Ada.Text_IO;
with Own_Checks;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Out_Text;
   Length : Out_Length_Type;
begin
   Input (1 .. 7) := "1.1.1.1";
   Defang (Input, 7, Output, Length);
   Assert (Length = 13 and then Output (1 .. 13) = "1[.]1[.]1[.]1");
   --  V&V sweep, agent A3: a longer input must be defanged completely:
   --  every '.' inside "[.]" and no character dropped. The 18 characters
   --  below defang to 34 = 18 + 2 * 8.
   Input := [others => ' '];
   Input (1 .. 18) := "12.1.1.1.1.1.1.1.1";
   Defang (Input, 18, Output, Length);
   for I in 1 .. Length loop
      if Output (I) = '.' then
         Assert (I > 1 and then I < Length
                 and then Output (I - 1) = '[' and then Output (I + 1) = ']',
                 "raw '.' left in the output at" & I'Image);
      end if;
   end loop;
   Assert (Length = 18 + 2 * 8, "output truncated to" & Length'Image);
   --  Hand-worked (V&V sweep, agent A3; tests/SOURCES.txt).
   Defang (Input, 0, Output, Length);
   Assert (Length = 0);
   Input (1 .. 15) := "255.255.255.255";
   Defang (Input, 15, Output, Length);
   Assert (Length = 21 and then String (Output (1 .. 21)) = "255[.]255[.]255[.]255");
   Input (1 .. 3) := "abc";
   Defang (Input, 3, Output, Length);
   Assert (Length = 3 and then String (Output (1 .. 3)) = "abc");
   Input := [others => '.'];
   Defang (Input, 32, Output, Length);
   Assert (Length = 96);
   for K in 0 .. 31 loop
      Assert (String (Output (3 * K + 1 .. 3 * K + 3)) = "[.]");
   end loop;
   Defang (Input, 1, Output, Length);
   Assert (Length = 3 and then String (Output (1 .. 3)) = "[.]");
   Input := [others => '7'];
   Input (32) := '.';
   Defang (Input, 31, Output, Length);
   Assert (Length = 31, "the character after Length is ignored");
   Defang (Input, 32, Output, Length);
   Assert (Length = 34 and then String (Output (31 .. 34)) = "7[.]");
   Own_Checks;
   Ada.Text_IO.Put_Line ("PASS Defanging_IP");
end Tests;
