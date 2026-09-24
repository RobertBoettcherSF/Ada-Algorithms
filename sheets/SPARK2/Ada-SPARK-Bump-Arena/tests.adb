pragma SPARK_Mode (Off);

with Ada.Text_IO; use Ada.Text_IO;
with Bump_Arena;  use Bump_Arena;
with Index_Tree;  use Index_Tree;

procedure Tests is
   Passes : Natural := 0;

   procedure Check (Cond : Boolean; Name : String) is
   begin
      if not Cond then
         Put_Line ("FAIL: " & Name);
         raise Program_Error with Name;
      end if;
      Passes := Passes + 1;
      Put_Line ("PASS: " & Name);
   end Check;

   A  : Arena := Create;
   Id : Node_Id;
   M  : Mark;
   T  : Tree := Empty;
   Ok : Boolean;
begin
   Check (Used (A) = 0 and then Remaining (A) = Capacity, "arena empty");

   Allocate_Node (A, Id);
   Check (Id = 1 and then Used (A) = 1, "allocate first");

   Allocate_Node (A, Id);
   Check (Id = 2 and then Used (A) = 2, "allocate second");

   M := Get_Mark (A);
   Check (Mark_Level (M) = 2, "mark at 2");

   Allocate_Node (A, Id);
   Allocate_Node (A, Id);
   Check (Used (A) = 4 and then Id = 4, "allocate after mark");

   Release (A, M);
   Check (Used (A) = 2 and then Remaining (A) = Capacity - 2, "release to mark");

   Reset (A);
   Check (Used (A) = 0, "reset arena");

   Check (Root_Of (T) = Null_Node and then Remaining_Slots (T) = Capacity,
          "tree empty");

   Insert (T, 50, Ok);
   Check (Ok and then Contains (T, 50) and then Root_Of (T) = 1, "insert root");

   Insert (T, 25, Ok);
   Check (Ok and then Contains (T, 25), "insert left");

   Insert (T, 75, Ok);
   Check (Ok and then Contains (T, 75), "insert right");

   Insert (T, 10, Ok);
   Insert (T, 30, Ok);
   Insert (T, 60, Ok);
   Insert (T, 90, Ok);
   Check (Ok and then Contains (T, 90)
            and then Used (Arena_Of (T)) = 7,
          "insert deeper");

   Insert (T, 50, Ok);
   Check (not Ok and then Used (Arena_Of (T)) = 7, "duplicate rejected");

   Check (not Contains (T, 42), "missing key");

   Clear (T);
   Check (Root_Of (T) = Null_Node and then Used (Arena_Of (T)) = 0
            and then not Contains (T, 50),
          "clear tree");

   --  Mark / Release LIFO on a fresh arena (scratch pattern)
   declare
      S   : Arena := Create;
      Mk  : Mark;
      Sid : Node_Id;
   begin
      Allocate_Node (S, Sid);
      Allocate_Node (S, Sid);
      Mk := Get_Mark (S);
      Allocate_Node (S, Sid);
      Allocate_Node (S, Sid);
      Check (Used (S) = 4, "scratch before release");
      Release (S, Mk);
      Check (Used (S) = 2, "scratch after release");
   end;

   Put_Line ("----------------");
   Put_Line ("All tests PASS:" & Passes'Image);
end Tests;
