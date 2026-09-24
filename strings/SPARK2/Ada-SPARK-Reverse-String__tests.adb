with Reverse_String;
procedure Tests is
   use type Reverse_String.Text_Array;
   Input : constant Reverse_String.Text_Array := "SPARK!";
   Expected : constant Reverse_String.Text_Array := "!KRAPS";
begin
   pragma Assert (Reverse_String.Reverse_Text (Input) = Expected);
end Tests;
