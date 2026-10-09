pragma Ada_2022;
with Ada.Assertions; use Ada.Assertions;
with Ada.Text_IO; use Ada.Text_IO;
with Accounts_Merge_Lite; use Accounts_Merge_Lite;
with Own_Checks;
procedure Tests is
   O : constant Owner_Array := [1 => 1, 2 => 2, 3 => 1, 4 => 3, others => 4];
begin
   Assert (Merge_Count (4, O) = 3);
   --  Hand-worked edge cases (V&V sweep, agent A3; tests/SOURCES.txt).
   declare
      All_Same : constant Owner_Array := [others => 7];
      Distinct : Owner_Array;
      Tail     : constant Owner_Array :=
        [1 => 5, 2 => 5, 3 => 9, others => 1];
      Late     : constant Owner_Array :=
        [1 => 2, 2 => 3, 3 => 2, 4 => 4, 5 => 3, 6 => 2, others => 30];
   begin
      for A in Account loop
         Distinct (A) := Max_Accounts + 1 - A;
      end loop;
      Assert (Merge_Count (1, O) = 1);
      Assert (Merge_Count (3, O) = 2);
      Assert (Merge_Count (5, O) = 4);
      Assert (Merge_Count (Max_Accounts, O) = 4);
      Assert (Merge_Count (1, All_Same) = 1);
      Assert (Merge_Count (Max_Accounts, All_Same) = 1);
      Assert (Merge_Count (Max_Accounts, Distinct) = Max_Accounts);
      Assert (Merge_Count (17, Distinct) = 17);
      Assert (Merge_Count (2, Tail) = 1);
      Assert (Merge_Count (3, Tail) = 2);
      Assert (Merge_Count (4, Tail) = 3);
      Assert (Merge_Count (Max_Accounts, Tail) = 3);
      Assert (Merge_Count (6, Late) = 3);
      Assert (Merge_Count (7, Late) = 4);
   end;
   Own_Checks;
   Put_Line ("PASS Accounts Merge Lite");
end Tests;
