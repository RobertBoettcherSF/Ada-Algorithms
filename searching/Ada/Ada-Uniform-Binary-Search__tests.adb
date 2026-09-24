--  Standalone test suite for Uniform_Binary_Search (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Uniform_Binary_Search; use Uniform_Binary_Search;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function I (X : Integer) return Integer is (X);

   function Sentinel (A : Element_Array) return Integer is
     (Integer (A'First) - 1);

   --  Presence check: found index must contain Key; miss must be sentinel.
   procedure Expect_Hit
     (A       : Element_Array;
      Key     : Integer;
      Label   : String)
   is
      U : constant Integer := Find (A, Key);
      C : constant Integer := Classic_Binary_Search (A, Key);
   begin
      Check (U >= Integer (A'First) and then U <= Integer (A'Last),
             Label & " uniform in range");
      if U >= Integer (A'First) and then U <= Integer (A'Last) then
         Check (A (Natural (U)) = Key, Label & " uniform value");
      else
         Check (False, Label & " uniform value (skipped)");
      end if;
      Check (C >= Integer (A'First) and then C <= Integer (A'Last),
             Label & " classic in range");
      if C >= Integer (A'First) and then C <= Integer (A'Last) then
         Check (A (Natural (C)) = Key, Label & " classic value");
      else
         Check (False, Label & " classic value (skipped)");
      end if;
   end Expect_Hit;

   procedure Expect_Miss
     (A     : Element_Array;
      Key   : Integer;
      Label : String)
   is
      U : constant Integer := Find (A, Key);
      C : constant Integer := Classic_Binary_Search (A, Key);
   begin
      Check (U = Sentinel (A), Label & " uniform miss");
      Check (C = Sentinel (A), Label & " classic miss");
   end Expect_Miss;

   --  Wikipedia example array (0-based).
   Wiki : constant Element_Array (0 .. 9) :=
     [1, 3, 5, 6, 7, 9, 14, 15, 17, 19];

   Empty_1 : Element_Array (1 .. 0);

   Single : constant Element_Array (0 .. 0) := [0 => 42];
   Single_1 : constant Element_Array (1 .. 1) := [1 => 7];

   Two : constant Element_Array (0 .. 1) := [10, 20];
   Dup : constant Element_Array (0 .. 5) := [1, 2, 2, 2, 3, 4];
   Neg : constant Element_Array (0 .. 4) := [-10, -3, 0, 5, 12];
   Pow2 : constant Element_Array (0 .. 7) :=
     [1, 2, 3, 4, 5, 6, 7, 8];
   Odd_N : constant Element_Array (0 .. 6) :=
     [2, 4, 6, 8, 10, 12, 14];

   Ones : constant Element_Array (5 .. 9) := [5 => 1, 6 => 1, 7 => 1, 8 => 1, 9 => 1];

   Table : Delta_Table;
   Big   : Element_Array (1 .. 200);
   Raised : Boolean;

begin
   Ada.Text_IO.Put_Line ("Uniform_Binary_Search tests");
   Ada.Text_IO.Put_Line ("===========================");

   ------------------------------------------------------------------
   Section ("1. Empty / singleton");
   ------------------------------------------------------------------
   declare
      E : Element_Array renames Empty_1;
   begin
      Check (E'Length = 0, "empty length 0");
      Check (Find (E, I (1)) = Sentinel (E), "empty find miss");
      Check (Classic_Binary_Search (E, I (1)) = Sentinel (E),
             "empty classic miss");
      Check (Is_Sorted_Ascending (E), "empty is sorted");
   end;

   --  Null slice of Wiki as another empty view
   declare
      E : constant Element_Array := Wiki (1 .. 0);
   begin
      Check (E'Length = 0, "null slice length 0");
      Check (Find (E, I (5)) = Sentinel (E), "null slice find miss");
   end;

   Expect_Hit (Single, 42, "singleton hit");
   Expect_Miss (Single, 0, "singleton miss low");
   Expect_Miss (Single, 100, "singleton miss high");
   Expect_Hit (Single_1, 7, "singleton 1-based hit");
   Expect_Miss (Single_1, 6, "singleton 1-based miss");

   ------------------------------------------------------------------
   Section ("2. Wikipedia N=10 example");
   ------------------------------------------------------------------
   Check (Is_Sorted_Ascending (Wiki), "wiki sorted");
   Build_Table (10, Table);
   Check (Table_Length (Table) = 10, "wiki table length");
   Check (Delta_At (Table, 0) = 5, "wiki delta[0]=5");
   Check (Delta_At (Table, 1) = 3, "wiki delta[1]=3");
   Check (Delta_At (Table, 2) = 1, "wiki delta[2]=1");
   Check (Delta_At (Table, 3) = 1, "wiki delta[3]=1");
   Check (Delta_At (Table, 4) = 0, "wiki delta[4]=0");
   Check (Table_Entry_Count (Table) = 5, "wiki entry count");

   --  Exact indices for unique keys
   Check (Find (Wiki, 1) = 0, "wiki find 1 -> 0");
   Check (Find (Wiki, 3) = 1, "wiki find 3 -> 1");
   Check (Find (Wiki, 5) = 2, "wiki find 5 -> 2");
   Check (Find (Wiki, 6) = 3, "wiki find 6 -> 3");
   Check (Find (Wiki, 7) = 4, "wiki find 7 -> 4");
   Check (Find (Wiki, 9) = 5, "wiki find 9 -> 5");
   Check (Find (Wiki, 14) = 6, "wiki find 14 -> 6");
   Check (Find (Wiki, 15) = 7, "wiki find 15 -> 7");
   Check (Find (Wiki, 17) = 8, "wiki find 17 -> 8");
   Check (Find (Wiki, 19) = 9, "wiki find 19 -> 9");

   Expect_Miss (Wiki, 0, "wiki miss 0");
   Expect_Miss (Wiki, 2, "wiki miss 2");
   Expect_Miss (Wiki, 4, "wiki miss 4");
   Expect_Miss (Wiki, 8, "wiki miss 8");
   Expect_Miss (Wiki, 10, "wiki miss 10");
   Expect_Miss (Wiki, 16, "wiki miss 16");
   Expect_Miss (Wiki, 18, "wiki miss 18");
   Expect_Miss (Wiki, 20, "wiki miss 20");

   --  Prebuilt table overload
   Check (Find (Wiki, 7, Table) = 4, "wiki find with table 7");
   Check (Find (Wiki, 0, Table) = Sentinel (Wiki), "wiki miss with table");

   ------------------------------------------------------------------
   Section ("3. Ends / middle / two elements");
   ------------------------------------------------------------------
   Expect_Hit (Two, 10, "two first");
   Expect_Hit (Two, 20, "two last");
   Expect_Miss (Two, 15, "two middle miss");
   Expect_Miss (Two, 9, "two below");
   Expect_Miss (Two, 21, "two above");

   Expect_Hit (Pow2, 1, "pow2 first");
   Expect_Hit (Pow2, 8, "pow2 last");
   Expect_Hit (Pow2, 4, "pow2 mid");
   Expect_Hit (Pow2, 5, "pow2 mid+1");
   Expect_Miss (Pow2, 0, "pow2 miss 0");
   Expect_Miss (Pow2, 9, "pow2 miss 9");

   Expect_Hit (Odd_N, 2, "odd first");
   Expect_Hit (Odd_N, 14, "odd last");
   Expect_Hit (Odd_N, 8, "odd mid");
   Expect_Miss (Odd_N, 7, "odd miss");

   ------------------------------------------------------------------
   Section ("4. Negatives / 1-based bounds / all equal");
   ------------------------------------------------------------------
   Expect_Hit (Neg, -10, "neg first");
   Expect_Hit (Neg, 12, "neg last");
   Expect_Hit (Neg, 0, "neg zero");
   Expect_Miss (Neg, -11, "neg below");
   Expect_Miss (Neg, 6, "neg gap");

   Expect_Hit (Ones, 1, "all-equal hit");
   Expect_Miss (Ones, 0, "all-equal miss");
   declare
      U : constant Integer := Find (Ones, 1);
   begin
      Check (U >= Integer (Ones'First) and then U <= Integer (Ones'Last),
             "all-equal index in 5..9");
      Check (Ones (Natural (U)) = 1, "all-equal value 1");
   end;

   ------------------------------------------------------------------
   Section ("5. Duplicates (any matching index)");
   ------------------------------------------------------------------
   --  Documented: Find may return any index of a duplicate run.
   declare
      U : constant Integer := Find (Dup, 2);
      C : constant Integer := Classic_Binary_Search (Dup, 2);
   begin
      Check (U in 1 .. 3, "dup uniform in run 1..3");
      Check (Dup (Natural (U)) = 2, "dup uniform value");
      Check (C in 1 .. 3, "dup classic in run 1..3");
      Check (Dup (Natural (C)) = 2, "dup classic value");
   end;
   Expect_Hit (Dup, 1, "dup first key");
   Expect_Hit (Dup, 4, "dup last key");
   Expect_Miss (Dup, 0, "dup miss 0");
   Expect_Miss (Dup, 5, "dup miss 5");

   ------------------------------------------------------------------
   Section ("6. Agreement with classic binary search");
   ------------------------------------------------------------------
   declare
      A : Element_Array (0 .. 49);
      Agree_Hits  : Natural := 0;
      Agree_Miss  : Natural := 0;
   begin
      for K in A'Range loop
         A (K) := K * 3;  -- 0,3,6,...,147
      end loop;
      Check (Is_Sorted_Ascending (A), "agree array sorted");

      Build_Table (A'Length, Table);
      for Key in -3 .. 150 loop
         declare
            U : constant Integer := Find (A, Key, Table);
            C : constant Integer := Classic_Binary_Search (A, Key);
         begin
            if U = Sentinel (A) and then C = Sentinel (A) then
               Agree_Miss := Agree_Miss + 1;
            elsif U >= Integer (A'First) and then U <= Integer (A'Last)
              and then C >= Integer (A'First) and then C <= Integer (A'Last)
              and then A (Natural (U)) = Key and then A (Natural (C)) = Key
            then
               Agree_Hits := Agree_Hits + 1;
            else
               Check (False,
                      "agree mismatch key=" & Integer'Image (Key));
            end if;
         end;
      end loop;
      Check (Agree_Hits = 50, "agree 50 hits");
      Check (Agree_Miss = 104, "agree 104 misses (-3..150 minus 50)");
      --  -3..150 is 154 keys; 50 present → 104 absent
   end;

   ------------------------------------------------------------------
   Section ("7. Larger array + Build_Table reuse");
   ------------------------------------------------------------------
   for K in Big'Range loop
      Big (K) := K;
   end loop;
   Check (Is_Sorted_Ascending (Big), "big sorted");
   Build_Table (Big'Length, Table);
   Check (Table_Length (Table) = 200, "big table N");
   Check (Delta_At (Table, Table_Entry_Count (Table) - 1) = 0,
          "big table ends with 0");
   Expect_Hit (Big, 1, "big first");
   Expect_Hit (Big, 200, "big last");
   Expect_Hit (Big, 100, "big mid");
   Expect_Miss (Big, 0, "big miss 0");
   Expect_Miss (Big, 201, "big miss 201");
   Check (Find (Big, 150, Table) = 150, "big prebuilt 150");

   ------------------------------------------------------------------
   Section ("8. Invalid_Argument");
   ------------------------------------------------------------------
   Raised := False;
   begin
      Build_Table (Max_N + 1, Table);
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Build_Table N>Max_N raises");

   Raised := False;
   declare
      Tiny : constant Element_Array (0 .. 2) := [1, 2, 3];
      Bad  : Delta_Table;
   begin
      Build_Table (5, Bad);  -- wrong length
      declare
         Dummy : Integer;
      begin
         Dummy := Find (Tiny, 2, Bad);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Find with mismatched table raises");

   Raised := False;
   begin
      declare
         Dummy : Natural;
      begin
         Build_Table (3, Table);
         Dummy := Delta_At (Table, 99);
         pragma Unreferenced (Dummy);
      end;
   exception
      when Invalid_Argument =>
         Raised := True;
   end;
   Check (Raised, "Delta_At OOB raises");

   ------------------------------------------------------------------
   Section ("9. Is_Sorted_Ascending");
   ------------------------------------------------------------------
   Check (Is_Sorted_Ascending (Wiki), "sorted wiki");
   Check (Is_Sorted_Ascending (Single), "sorted single");
   declare
      Bad : constant Element_Array (0 .. 3) := [1, 3, 2, 4];
   begin
      Check (not Is_Sorted_Ascending (Bad), "unsorted detected");
   end;
   Check (Is_Sorted_Ascending (Dup), "sorted dups");
   Check (Is_Sorted_Ascending (Ones), "sorted equals");

   ------------------------------------------------------------------
   Section ("10. Power-of-two lengths delta shape");
   ------------------------------------------------------------------
   Build_Table (1, Table);
   Check (Delta_At (Table, 0) = 1, "N=1 delta0");
   Check (Delta_At (Table, 1) = 0, "N=1 delta1");

   Build_Table (2, Table);
   Check (Delta_At (Table, 0) = 1, "N=2 delta0");
   --  (2+1)/2=1, (2+2)/4=1, (2+4)/8=0
   Check (Delta_At (Table, 1) = 1, "N=2 delta1");
   Check (Delta_At (Table, 2) = 0, "N=2 delta2");

   Build_Table (8, Table);
   Check (Delta_At (Table, 0) = 4, "N=8 delta0");
   Check (Delta_At (Table, 1) = 2, "N=8 delta1");
   Check (Delta_At (Table, 2) = 1, "N=8 delta2");

   Build_Table (16, Table);
   Check (Delta_At (Table, 0) = 8, "N=16 delta0");
   Check (Delta_At (Table, 1) = 4, "N=16 delta1");
   Check (Delta_At (Table, 2) = 2, "N=16 delta2");
   Check (Delta_At (Table, 3) = 1, "N=16 delta3");

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
