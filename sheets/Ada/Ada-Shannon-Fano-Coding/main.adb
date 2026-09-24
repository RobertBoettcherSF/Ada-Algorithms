with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Shannon_Fano; use Shannon_Fano;

procedure Main is
   Test_Symbols : Symbol_Array := 
     ((Symbol => 'A', Probability => 15.0, Code => Null_Unbounded_String),
      (Symbol => 'B', Probability => 7.0,  Code => Null_Unbounded_String),
      (Symbol => 'C', Probability => 6.0,  Code => Null_Unbounded_String),
      (Symbol => 'D', Probability => 6.0,  Code => Null_Unbounded_String),
      (Symbol => 'E', Probability => 5.0,  Code => Null_Unbounded_String));
begin
   Put_Line ("Running Fano's Method (Recursive Splitting):");
   Generate_Fano_Codes (Test_Symbols);
   for I in Test_Symbols'Range loop
      Put_Line (Test_Symbols(I).Symbol & " : " & To_String (Test_Symbols(I).Code));
   end loop;

   New_Line;

   Put_Line ("Running Shannon's Method (Cumulative/Logarithmic):");
   Generate_Shannon_Codes (Test_Symbols);
   for I in Test_Symbols'Range loop
      Put_Line (Test_Symbols(I).Symbol & " : " & To_String (Test_Symbols(I).Code));
   end loop;
end Main;
