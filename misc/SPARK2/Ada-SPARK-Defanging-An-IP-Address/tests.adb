with Ada.Assertions; use Ada.Assertions;
with Defanging_IP; use Defanging_IP;
procedure Tests is
   Input : Text := [others => ' '];
   Output : Text;
   Length : Length_Type;
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
   Assert (Natural (Length) = 18 + 2 * 8, "output truncated to" & Length'Image);
end Tests;
