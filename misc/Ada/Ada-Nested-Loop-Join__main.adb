with Ada.Text_IO; use Ada.Text_IO;

procedure Main is
begin
   Put_Line ("===============================================");
   Put_Line (" Nested Loop Join Implementation in Ada ");
   Put_Line ("===============================================");
   Put_Line ("Contains:");
   Put_Line (" - Naive_Nested_Loop_Join");
   Put_Line (" - Block_Nested_Loop_Join");
   Put_Line (" - Index_Nested_Loop_Join");
   Put_Line ("");
   Put_Line ("To verify the systems, run the test suite:");
   Put_Line ("  $ make test");
   Put_Line ("===============================================");
end Main;
