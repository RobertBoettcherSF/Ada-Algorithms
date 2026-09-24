--  Standalone test suite for Sort_Merge_Join (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Nondecreasing Left.Key on Result is proved by SPARK; matching /
--  Cartesian correctness is checked here.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sort_Merge_Join; use Sort_Merge_Join;

procedure Tests
  with SPARK_Mode => Off
is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function R (K, P : Integer) return Row is
     ((Key => K, Payload => P));

   function Same_Pair (A, B : Joined_Row) return Boolean is
     (A.Left = B.Left and then A.Right = B.Right);

   procedure Check_Join_Sorted
     (Result : Joined_Relation;
      Last   : Natural;
      Msg    : String)
   is
      OK : Boolean := True;
   begin
      if Last > 1 then
         for I in 1 .. Last - 1 loop
            if Result (I).Left.Key > Result (I + 1).Left.Key then
               OK := False;
               exit;
            end if;
         end loop;
      end if;
      Check (OK, Msg);
   end Check_Join_Sorted;

   procedure Check_All_Match
     (Result : Joined_Relation;
      Last   : Natural;
      Msg    : String)
   is
      OK : Boolean := True;
   begin
      for I in 1 .. Last loop
         if Result (I).Left.Key /= Result (I).Right.Key then
            OK := False;
            exit;
         end if;
      end loop;
      Check (OK, Msg);
   end Check_All_Match;

   Empty : Relation (1 .. 0);
   Buf   : Joined_Relation (1 .. Max_Out);
   Last  : Natural;

begin
   Put_Line ("Sort_Merge_Join SPARK Level 4 — test suite");
   Put_Line ("Assumption: code is incorrect until assertions pass.");

   -------------------------------------------------------------------------
   Section ("Helpers: Is_Sorted_By_Key / Keys_Unique / Product_Fits");
   -------------------------------------------------------------------------
   Check (Is_Sorted_By_Key (Empty), "empty is sorted");
   Check (Keys_Unique (Empty), "empty keys unique");
   Check (Is_Sorted_By_Key ([1 => R (1, 10)]), "singleton sorted");
   Check (Keys_Unique ([1 => R (1, 10)]), "singleton unique");
   Check
     (Is_Sorted_By_Key ([R (1, 0), R (2, 0), R (2, 1)]),
      "nondecreasing with duplicate keys sorted");
   Check
     (not Is_Sorted_By_Key ([R (2, 0), R (1, 0)]),
      "inverse not sorted");
   Check
     (not Keys_Unique ([R (1, 0), R (1, 1)]),
      "duplicate keys not unique");
   Check
     (Keys_Unique ([R (1, 0), R (2, 0), R (5, 0)]),
      "strictly increasing unique");
   Check (Product_Fits (Empty, Empty), "0*0 fits");
   Check
     (Product_Fits ([1 => R (1, 0)], [R (1, 0), R (2, 0)]),
      "1*2 fits");
   Check
     (not Product_Fits
        ([for I in 1 .. 17 => R (1, 0)], [for I in 1 .. 16 => R (1, 0)]),
      "17*16 exceeds Max_Out");

   -------------------------------------------------------------------------
   Section ("Boundary & empty Inner_Join");
   -------------------------------------------------------------------------
   Inner_Join (Empty, [1 => R (1, 1)], Buf, Last);
   Check (Last = 0, "empty Left yields 0");
   Inner_Join ([1 => R (1, 1)], Empty, Buf, Last);
   Check (Last = 0, "empty Right yields 0");
   Inner_Join (Empty, Empty, Buf, Last);
   Check (Last = 0, "both empty yields 0");

   -------------------------------------------------------------------------
   Section ("Functional Inner_Join (standard matches)");
   -------------------------------------------------------------------------
   Inner_Join ([1 => R (1, 10)], [1 => R (2, 20)], Buf, Last);
   Check (Last = 0, "no overlapping keys");

   Inner_Join ([1 => R (1, 10)], [1 => R (1, 20)], Buf, Last);
   Check
     (Last = 1
      and then Buf (1).Left.Payload = 10
      and then Buf (1).Right.Payload = 20,
      "one-to-one match");
   Check_All_Match (Buf, Last, "one-to-one keys equal");
   Check_Join_Sorted (Buf, Last, "one-to-one Left.Key sorted");

   Inner_Join
     ([R (1, 1), R (2, 2)],
      [R (1, 10), R (2, 20)],
      Buf, Last);
   Check (Last = 2, "two distinct 1-1 matches");
   Check_All_Match (Buf, Last, "two 1-1 keys equal");
   Check_Join_Sorted (Buf, Last, "two 1-1 Left.Key sorted");
   Check
     (Buf (1).Left.Payload = 1 and then Buf (1).Right.Payload = 10
      and then Buf (2).Left.Payload = 2 and then Buf (2).Right.Payload = 20,
      "two 1-1 payloads");

   -------------------------------------------------------------------------
   Section ("Cartesian multiplicity");
   -------------------------------------------------------------------------
   Inner_Join
     ([1 => R (1, 100)],
      [R (1, 1), R (1, 2)],
      Buf, Last);
   Check (Last = 2, "one-to-many yields 2");
   Check_All_Match (Buf, Last, "one-to-many keys equal");
   Check
     (Buf (1).Right.Payload = 1 and then Buf (2).Right.Payload = 2,
      "one-to-many right payloads");

   Inner_Join
     ([R (1, 1), R (1, 2)],
      [1 => R (1, 100)],
      Buf, Last);
   Check (Last = 2, "many-to-one yields 2");
   Check
     (Buf (1).Left.Payload = 1 and then Buf (2).Left.Payload = 2,
      "many-to-one left payloads");

   Inner_Join
     ([R (1, 1), R (1, 2)],
      [R (1, 10), R (1, 20)],
      Buf, Last);
   Check (Last = 4, "many-to-many yields 2*2=4");
   Check_All_Match (Buf, Last, "many-to-many keys equal");
   Check_Join_Sorted (Buf, Last, "many-to-many Left.Key sorted");
   Check
     (Same_Pair (Buf (1), (Left => R (1, 1), Right => R (1, 10)))
      and then Same_Pair (Buf (2), (Left => R (1, 1), Right => R (1, 20)))
      and then Same_Pair (Buf (3), (Left => R (1, 2), Right => R (1, 10)))
      and then Same_Pair (Buf (4), (Left => R (1, 2), Right => R (1, 20))),
      "many-to-many Cartesian order");

   -------------------------------------------------------------------------
   Section ("Mixed keys, negatives, gaps");
   -------------------------------------------------------------------------
   Inner_Join
     ([R (-5, 1), R (0, 2), R (3, 3)],
      [R (-5, 10), R (1, 11), R (3, 12), R (3, 13)],
      Buf, Last);
   Check (Last = 3, "mixed: (-5) + two on key 3");
   Check_All_Match (Buf, Last, "mixed keys equal");
   Check_Join_Sorted (Buf, Last, "mixed Left.Key sorted");
   Check
     (Buf (1).Left.Key = -5
      and then Buf (2).Left.Key = 3
      and then Buf (3).Left.Key = 3
      and then Buf (2).Right.Payload = 12
      and then Buf (3).Right.Payload = 13,
      "mixed payloads / order");

   Inner_Join
     ([R (1, 1), R (1, 2), R (5, 5)],
      [R (1, 10), R (3, 30), R (5, 50), R (5, 51)],
      Buf, Last);
   Check (Last = 4, "two runs: 1x1 + 1x2 on key 5");
   Check_Join_Sorted (Buf, Last, "two-run Left.Key sorted");

   -------------------------------------------------------------------------
   Section ("Unique_Key_Join");
   -------------------------------------------------------------------------
   Unique_Key_Join
     ([R (1, 1), R (2, 2)],
      [1 => R (1, 10)],
      Buf, Last);
   Check (Last = 1 and then Buf (1).Right.Payload = 10,
          "unique left one match");

   Unique_Key_Join
     ([R (1, 1), R (3, 3)],
      [R (1, 10), R (1, 11), R (3, 30)],
      Buf, Last);
   Check (Last = 3, "unique left one-to-many + one-to-one");
   Check_All_Match (Buf, Last, "unique-key keys equal");
   Check_Join_Sorted (Buf, Last, "unique-key Left.Key sorted");
   Check
     (Buf (1).Left.Payload = 1 and then Buf (1).Right.Payload = 10
      and then Buf (2).Left.Payload = 1 and then Buf (2).Right.Payload = 11
      and then Buf (3).Left.Payload = 3 and then Buf (3).Right.Payload = 30,
      "unique-key payloads");

   Unique_Key_Join
     ([R (1, 1), R (2, 2)],
      [1 => R (9, 9)],
      Buf, Last);
   Check (Last = 0, "unique left no overlap");

   Unique_Key_Join (Empty, [1 => R (1, 1)], Buf, Last);
   Check (Last = 0, "unique empty Left");

   -------------------------------------------------------------------------
   Section ("Capacity / classroom bounds");
   -------------------------------------------------------------------------
   declare
      L16 : Relation (1 .. 16);
      R16 : Relation (1 .. 16);
   begin
      for I in L16'Range loop
         L16 (I) := R (I, I);
         R16 (I) := R (I, I + 100);
      end loop;
      Check (Product_Fits (L16, R16), "16*16=256 fits exactly");
      Inner_Join (L16, R16, Buf, Last);
      Check (Last = 16, "16 distinct 1-1 pairs");
      Check_Join_Sorted (Buf, Last, "16-pair Left.Key sorted");
      Check_All_Match (Buf, Last, "16-pair keys equal");
   end;

   declare
      L8 : Relation (1 .. 8);
      R8 : Relation (1 .. 8);
   begin
      for I in L8'Range loop
         L8 (I) := R (1, I);       -- all key 1
         R8 (I) := R (1, I + 10);  -- all key 1
      end loop;
      Check (Product_Fits (L8, R8), "8*8=64 fits");
      Inner_Join (L8, R8, Buf, Last);
      Check (Last = 64, "full Cartesian 8*8");
      Check_All_Match (Buf, Last, "8*8 keys equal");
   end;

   -------------------------------------------------------------------------
   Section ("Summary");
   -------------------------------------------------------------------------
   New_Line;
   Put_Line
     ("Result: " & Natural'Image (Pass_Count) & " PASS, "
      & Natural'Image (Fail_Count) & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
