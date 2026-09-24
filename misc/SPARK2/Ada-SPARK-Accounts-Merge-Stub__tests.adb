pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Accounts_Merge_Stub; use Accounts_Merge_Stub;

procedure Tests is
   Accounts : constant Account_Array :=
     (1 => (Owner => 1, Email1 => 1, Email2 => 2),
      2 => (Owner => 2, Email1 => 2, Email2 => 3),
      3 => (Owner => 3, Email1 => 4, Email2 => 5),
      4 => (Owner => 4, Email1 => 6, Email2 => 6));
begin
   if Merged_Account_Count (Accounts) /= 3 then raise Program_Error; end if;
   Put_Line ("Accounts merge: PASS");
end Tests;
