pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions;
with House_Robber_III_Lite; use House_Robber_III_Lite;

--  Every expected value is worked out by hand in the comments (see
--  tests/SOURCES.txt). Nodes are numbered in preorder; Left/Right 0 means
--  no child.
with Own_Checks;
procedure Tests is
   procedure Expect (T : Tree; Want : Natural; Want_Choice : Choice; Label : String) is
      Got   : constant Natural := Max_Loot (T);
      Picks : constant Choice := Best_Choice (T);
   begin
      if Got /= Want then
         raise Program_Error with Label & ": Max_Loot" & Got'Image & ", expected" & Want'Image;
      end if;
      if Picks'First /= 1 or else Picks'Length /= Want_Choice'Length or else Picks /= Want_Choice then
         raise Program_Error with Label & ": Best_Choice differs";
      end if;
   end Expect;

   --  A path of K houses worth 1 each, every house the left child of the one before.
   function Unit_Path (K : Node_Count) return Tree is
      T : Tree (K);
   begin
      for I in 1 .. K loop
         T.Value (I) := 1;
         T.Left (I) := (if I < K then I + 1 else 0);
         T.Right (I) := 0;
      end loop;
      return T;
   end Unit_Path;

   Empty : constant Tree := (N => 0, Value => [], Left => [], Right => []);
   One   : constant Tree := (N => 1, Value => [7], Left => [0], Right => [0]);
   --  Root 4 with left child 5 (children 1 and 3) and right child 2 (right
   --  child 9). Bottom up, (take, skip): 1 -> (1, 0), 3 -> (3, 0),
   --  9 -> (9, 0); 5 -> (5, 1 + 3) = (5, 4); 2 -> (2, 9); root ->
   --  (4 + 4 + 9, 5 + 9) = (17, 14). Taking the root blocks 5 and 2, then
   --  1, 3 and 9 are taken: 4 + 1 + 3 + 9 = 17.
   Six   : constant Tree := (N => 6, Value => [4, 5, 1, 3, 2, 9],
                             Left => [2, 3, 0, 0, 0, 0], Right => [5, 4, 0, 0, 6, 0]);
   --  A left path 2, 7, 9, 3, 1: alternate houses 2 + 9 + 1 = 12 beat
   --  7 + 3 = 10 and every other independent choice.
   Path  : constant Tree := (N => 5, Value => [2, 7, 9, 3, 1],
                             Left => [2, 3, 4, 5, 0], Right => [0, 0, 0, 0, 0]);
   --  A right path 10, 1, 10: 10 + 10 = 20.
   Right_Path : constant Tree := (N => 3, Value => [10, 1, 10],
                                  Left => [0, 0, 0], Right => [2, 3, 0]);
   --  A tie: root 5, left child 5. Take = skip = 5; a node is taken on a tie.
   Tie   : constant Tree := (N => 2, Value => [5, 5], Left => [2, 0], Right => [0, 0]);
   --  A root 0 whose two children 6 and 6 are better than it: 12.
   Fork  : constant Tree := (N => 3, Value => [0, 6, 6], Left => [2, 0, 0], Right => [3, 0, 0]);
   --  Not in preorder: the right child of the root must be 3 (after the
   --  left subtree {2}), not 2.
   Bad   : constant Tree := (N => 3, Value => [1, 1, 1], Left => [3, 0, 0], Right => [2, 0, 0]);
   Big_Path : Tree (Max_Nodes);
   Want_Alt : Choice (1 .. Max_Nodes);
begin
   --  The old table: a unit path of K houses gives ceil (K / 2).
   for K in 0 .. 16 loop
      if Max_Loot (Unit_Path (K)) /= (K + 1) / 2 then
         raise Program_Error with "unit path" & K'Image;
      end if;
   end loop;
   Expect (Empty, 0, [], "empty");
   Expect (One, 7, [True], "one");
   Expect (Six, 17, [True, False, True, True, False, True], "six");
   Expect (Path, 12, [True, False, True, False, True], "path");
   Expect (Right_Path, 20, [True, False, True], "right path");
   Expect (Tie, 5, [True, False], "tie");
   Expect (Fork, 12, [False, True, True], "fork");

   --  The limits: a path of Max_Nodes houses worth Max_Value; every other
   --  house from the root, 50 * 10_000 = 500_000.
   for I in 1 .. Max_Nodes loop
      Big_Path.Value (I) := Max_Value;
      Big_Path.Left (I) := (if I < Max_Nodes then I + 1 else 0);
      Big_Path.Right (I) := 0;
      Want_Alt (I) := I mod 2 = 1;
   end loop;
   Expect (Big_Path, 500_000, Want_Alt, "long path");

   begin
      Put_Line ("bad tree gave" & Max_Loot (Bad)'Image);
      raise Program_Error with "a tree not in preorder was accepted";
   exception
      when Ada.Assertions.Assertion_Error =>
         null;
   end;
   --  H180: the 1-based pin is the subtype One_Based_Choice (predicate
   --  'First = 1, any length), not an S'First = 1 precondition. First a
   --  check that assertions are on (-gnata in house_robber_iii_lite.gpr),
   --  else the call checks below could never fail.
   declare
      Assertions_On : Boolean := False;
   begin
      begin
         pragma Assert (Max_Loot (One) = 0);   --  it is 7
      exception
         when Ada.Assertions.Assertion_Error =>
            Assertions_On := True;
      end;
      if not Assertions_On then
         raise Program_Error with "assertions are off (-gnata missing)";
      end if;
   end;
   declare
      Normal  : constant Choice (1 .. 3) := [True, False, True];
      Shifted : constant Choice (5 .. 7) := Normal;
      Raised  : Boolean := False;
   begin
      pragma Assert (Normal in One_Based_Choice);
      pragma Assert (not (Shifted in One_Based_Choice));
      if Normal not in One_Based_Choice or else Shifted in One_Based_Choice then
         raise Program_Error with "One_Based_Choice membership";
      end if;
      if Best_Choice (Right_Path) not in One_Based_Choice then
         raise Program_Error with "Best_Choice result not in One_Based_Choice";
      end if;
      --  Independent takes a One_Based_Choice: the 5 .. 7 choice must fail
      --  the predicate check on the parameter.
      begin
         Put_Line ("shifted choice gave " & Independent (Right_Path, Shifted)'Image);
      exception
         when Ada.Assertions.Assertion_Error =>
            Raised := True;
      end;
      if not Raised then
         raise Program_Error with "Independent (5 .. 7) did not raise Assertion_Error";
      end if;
   end;
   Put_Line ("PASS House_Robber_III_Lite");
   Own_Checks;
end Tests;
