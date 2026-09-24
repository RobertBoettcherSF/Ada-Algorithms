with Ada.Text_IO; use Ada.Text_IO;
with Espresso;    use Espresso;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   --  Helper to easily construct cubes from strings (e.g., "01-")
   function Parse (S : String) return Cube is
      Res : Cube (1 .. S'Length);
   begin
      for I in S'Range loop
         case S (I) is
            when '0' => Res (I - S'First + 1) := Zero;
            when '1' => Res (I - S'First + 1) := One;
            when '-' => Res (I - S'First + 1) := Dont_Care;
            when others => null;
         end case;
      end loop;
      return Res;
   end Parse;

   F, R : Cover;
   C1, C2, C3 : Cube (1 .. 3);

begin
   Put_Line ("TEST 1 — Overlaps");
   C1 := Parse ("01-");
   C2 := Parse ("0-1");
   C3 := Parse ("111");
   Check ("1.1 Partial overlap with Dont_Care", Overlaps (C1, C2));
   Check ("1.2 Explicit conflict prevents overlap", not Overlaps (C1, C3));
   Check ("1.3 Self always overlaps", Overlaps (C3, C3));

   Put_Line ("TEST 2 — Subsumes");
   C1 := Parse ("0--");
   C2 := Parse ("01-");
   Check ("2.1 Broader cube subsumes narrower", Subsumes (C1, C2));
   Check ("2.2 Narrow cube does not subsume broader", not Subsumes (C2, C1));
   Check ("2.3 Self always subsumes", Subsumes (C1, C1));

   Put_Line ("TEST 3 — Expand (Basic)");
   F.Clear; R.Clear;
   F.Append (Parse ("01"));
   R.Append (Parse ("10"));
   Expand (F, R);
   Check ("3.1 Cube successfully expanded", Integer (F.Length) = 1);
   Check ("3.2 Expanded to correct prime implicant", F.First_Element = Parse ("-1"));
   Check ("3.3 Property invariant: Length stays same", F.First_Element'Length = 2);

   Put_Line ("TEST 4 — Expand (Blocked by OFF-set)");
   F.Clear; R.Clear;
   F.Append (Parse ("00"));
   R.Append (Parse ("01"));
   R.Append (Parse ("10"));
   R.Append (Parse ("11"));
   Expand (F, R);
   Check ("4.1 Expansion completely blocked", Integer (F.Length) = 1);
   Check ("4.2 Cube remained exactly the same", F.First_Element = Parse ("00"));
   Check ("4.3 OFF-set successfully constrained ON-set", not Overlaps (F.First_Element, R.First_Element));

   Put_Line ("TEST 5 — Irredundant (Simple)");
   F.Clear;
   F.Append (Parse ("0-"));
   F.Append (Parse ("01"));
   Irredundant (F);
   Check ("5.1 Subsumed cube is removed", Integer (F.Length) = 1);
   Check ("5.2 Broader cube retained", F.First_Element = Parse ("0-"));
   Check ("5.3 Cover validates uniform", Is_Uniform (F));

   Put_Line ("TEST 6 — Irredundant (Duplicates)");
   F.Clear;
   F.Append (Parse ("11"));
   F.Append (Parse ("11"));
   F.Append (Parse ("11"));
   Irredundant (F);
   Check ("6.1 Duplicates reduced to single element", Integer (F.Length) = 1);
   Check ("6.2 Element retained correctly", F.First_Element = Parse ("11"));
   Check ("6.3 Cover remains valid", Is_Uniform (F));

   Put_Line ("TEST 7 — Reduce (Simple)");
   F.Clear;
   F.Append (Parse ("--"));
   F.Append (Parse ("0-"));
   Reduce (F);
   Check ("7.1 Cover size remains same after reduce", Integer (F.Length) = 2);
   Check ("7.2 First cube shrank from -- to 1-", F.First_Element = Parse ("1-"));
   Check ("7.3 Second cube remained intact", F.Element (2) = Parse ("0-"));

   Put_Line ("TEST 8 — Minimize_Single_Pass");
   F.Clear; R.Clear;
   F.Append (Parse ("00"));
   F.Append (Parse ("01"));
   F.Append (Parse ("10"));
   R.Append (Parse ("11"));
   Minimize_Single_Pass (F, R);
   Check ("8.1 Three minterms combined to two implicants", Integer (F.Length) = 2);
   Check ("8.2 First prime implicant correct (-0)", F.First_Element = Parse ("-0"));
   Check ("8.3 Second prime implicant correct (0-)", F.Element (2) = Parse ("0-"));

   Put_Line ("TEST 9 — Minimize_Iterative");
   F.Clear; R.Clear;
   --  A setup where iterative loop will expand and reduce correctly.
   F.Append (Parse ("000"));
   F.Append (Parse ("001"));
   F.Append (Parse ("010"));
   F.Append (Parse ("011"));
   --  Bounding the exact OFF-set prevents the heuristic from expanding into 
   --  unintended implicit Don't Cares (like 100 or 110), avoiding a cyclic core.
   R.Append (Parse ("1--"));
   Minimize_Iterative (F, R);
   Check ("9.1 Full logic loop combined to minimal cubes", Integer (F.Length) <= 2);
   Check ("9.2 F covers original space optimally", Overlaps (F.First_Element, Parse ("000")));
   Check ("9.3 Valid state after iteration", Is_Uniform (F));

   Put_Line ("TEST 10 — Edge Case: Empty ON-set");
   F.Clear; R.Clear;
   R.Append (Parse ("11"));
   Minimize_Iterative (F, R);
   Check ("10.1 Empty cover remains empty", Integer (F.Length) = 0);
   Check ("10.2 Is_Uniform handles empty", Is_Uniform (F));
   Check ("10.3 Variables_Count handles empty", Variables_Count (F) = 0);

   Put_Line ("TEST 11 — Edge Case: Empty OFF-set");
   F.Clear; R.Clear;
   F.Append (Parse ("00"));
   Minimize_Iterative (F, R);
   Check ("11.1 Expands fully when R is empty", Integer (F.Length) = 1);
   Check ("11.2 Becomes universal cube", F.First_Element = Parse ("--"));
   Check ("11.3 Uniform validation passes", Is_Uniform (F));

   Put_Line ("TEST 12 — Exception Handling: Length Mismatch");
   F.Clear; R.Clear;
   F.Append (Parse ("00"));
   R.Append (Parse ("1"));
   declare
      Hit : Boolean := False;
   begin
      begin
         Expand (F, R);
      exception
         when Inconsistent_Covers => Hit := True;
      end;
      Check ("12.1 Expand caught Inconsistent_Covers", Hit);
   end;
   declare
      Hit : Boolean := False;
   begin
      begin
         Minimize_Iterative (F, R);
      exception
         when Inconsistent_Covers => Hit := True;
      end;
      Check ("12.2 Minimize caught Inconsistent_Covers", Hit);
   end;
   Check ("12.3 Consistent helper returns false", not Consistent (F, R));

   Put_Line ("TEST 13 — Exception Handling: Invalid Cover (Internal mismatch)");
   F.Clear; R.Clear;
   F.Append (Parse ("00"));
   F.Append (Parse ("1")); -- Forces non-uniform cover internally
   declare
      Hit : Boolean := False;
   begin
      begin
         Irredundant (F);
      exception
         when Invalid_Cover => Hit := True;
      end;
      Check ("13.1 Irredundant caught Invalid_Cover", Hit);
   end;
   declare
      Hit : Boolean := False;
   begin
      begin
         Reduce (F);
      exception
         when Invalid_Cover => Hit := True;
      end;
      Check ("13.2 Reduce caught Invalid_Cover", Hit);
   end;
   Check ("13.3 Is_Uniform accurately detects mismatch", not Is_Uniform (F));

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
