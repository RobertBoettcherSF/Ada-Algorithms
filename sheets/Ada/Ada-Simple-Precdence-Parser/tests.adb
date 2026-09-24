with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Simple_Precedence_Parser; use Simple_Precedence_Parser;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Contains (Source, Pattern : String) return Boolean is
   begin
      if Pattern'Length > Source'Length then
         return False;
      end if;
      for I in Source'First .. Source'Last - Pattern'Length + 1 loop
         if Source (I .. I + Pattern'Length - 1) = Pattern then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   -- Valid Grammar Data: S -> aSb | c
   Valid_Prods : constant Production_Array :=
     [1 => (LHS => 'S', RHS => To_Unbounded_String ("aSb")),
      2 => (LHS => 'S', RHS => To_Unbounded_String ("c"))];

   -- Invalid Grammar Data: Duplicate RHS A -> x, B -> x
   Invalid_Prods_Dup : constant Production_Array :=
     [1 => (LHS => 'A', RHS => To_Unbounded_String ("x")),
      2 => (LHS => 'B', RHS => To_Unbounded_String ("x"))];

   -- Invalid Grammar Data: Empty RHS C -> ""
   Invalid_Prods_Empty : constant Production_Array :=
     [1 => (LHS => 'C', RHS => Null_Unbounded_String)];

   -- Matrix initialization for standard tests
   Valid_Matrix : Relation_Matrix := [others => [others => None]];
   
   -- Broken Matrix for testing Handle failure
   Broken_Matrix : Relation_Matrix := [others => [others => None]];

   Trace_Output : Unbounded_String;

begin
   -- Initialize Valid_Matrix for grammar S -> aSb | c
   Valid_Matrix ('$', 'a') := Takes;
   Valid_Matrix ('$', 'c') := Takes;
   Valid_Matrix ('a', 'a') := Takes;
   Valid_Matrix ('a', 'c') := Takes;
   Valid_Matrix ('a', 'S') := Equal;
   Valid_Matrix ('S', 'b') := Equal;
   Valid_Matrix ('c', 'b') := Yields;
   Valid_Matrix ('c', '$') := Yields;
   Valid_Matrix ('b', 'b') := Yields;
   Valid_Matrix ('b', '$') := Yields;

   -- TEST 1 - Validate Correct Grammar
   Put_Line ("TEST 1 - Grammar Validation (Positive)");
   Check ("1.1 Valid simple precedence grammar recognized", Is_Valid_Simple_Precedence_Grammar (Valid_Prods));
   Check ("1.2 Valid rules count is correct", Valid_Prods'Length = 2);
   Check ("1.3 Start symbol validity via direct bounds check", Valid_Prods(1).LHS = 'S');

   -- TEST 2 - Validate Grammar with Duplicate RHS
   Put_Line ("TEST 2 - Grammar Validation (Duplicate RHS)");
   Check ("2.1 Duplicate grammar rejected", not Is_Valid_Simple_Precedence_Grammar (Invalid_Prods_Dup));
   Check ("2.2 Invalid duplicate RHS check A", To_String (Invalid_Prods_Dup(1).RHS) = "x");
   Check ("2.3 Invalid duplicate RHS check B", To_String (Invalid_Prods_Dup(2).RHS) = "x");

   -- TEST 3 - Validate Grammar with Empty RHS
   Put_Line ("TEST 3 - Grammar Validation (Empty RHS)");
   Check ("3.1 Empty RHS grammar rejected", not Is_Valid_Simple_Precedence_Grammar (Invalid_Prods_Empty));
   Check ("3.2 RHS is literally empty", Length (Invalid_Prods_Empty(1).RHS) = 0);
   Check ("3.3 LHS assignment intact", Invalid_Prods_Empty(1).LHS = 'C');

   declare
      -- Static initialization of the Parser for the remaining tests
      Standard_Parser : constant Parser := Create_Parser ('S', Valid_Prods, Valid_Matrix);
   begin
      -- TEST 4 - Parser Instantiation and Setup Properties
      Put_Line ("TEST 4 - Parser Initialization");
      Check ("4.1 Creation succeeds without exception", True);
      Check ("4.2 Parser rejects incorrect string immediately", not Parse (Standard_Parser, ""));
      Check ("4.3 Trace defaults properly on setup", Parse_With_Trace (Standard_Parser, "", Trace_Output) = False);

      -- TEST 5 - Parse Valid Short Terminal
      Put_Line ("TEST 5 - Parse Valid Single Symbol");
      Check ("5.1 Parse 'c' -> True", Parse (Standard_Parser, "c"));
      Check ("5.2 Parse_With_Trace 'c' -> True", Parse_With_Trace (Standard_Parser, "c", Trace_Output));
      Check ("5.3 Trace includes correct accept text", Contains (To_String (Trace_Output), "Accept."));

      -- TEST 6 - Parse Valid Simple Recursive String
      Put_Line ("TEST 6 - Parse Valid String 'acb'");
      Check ("6.1 Parse 'acb' -> True", Parse (Standard_Parser, "acb"));
      Check ("6.2 Parse_With_Trace 'acb' records output", Parse_With_Trace (Standard_Parser, "acb", Trace_Output));
      Check ("6.3 Trace contains reduction to S", Contains (To_String (Trace_Output), "Reduce: S -> c"));

      -- TEST 7 - Parse Valid Deeply Recursive String
      Put_Line ("TEST 7 - Parse Valid String 'aacbb'");
      Check ("7.1 Parse 'aacbb' -> True", Parse (Standard_Parser, "aacbb"));
      Check ("7.2 Parse_With_Trace sets out-param strictly true", Parse_With_Trace (Standard_Parser, "aacbb", Trace_Output));
      Check ("7.3 Trace contains composite handle reduction", Contains (To_String (Trace_Output), "Reduce: S -> aSb"));

      -- TEST 8 - Edge Case: Empty String
      Put_Line ("TEST 8 - Edge Case Empty Input");
      Check ("8.1 Standard parse fails cleanly", not Parse (Standard_Parser, ""));
      Check ("8.2 Trace variant fails cleanly", not Parse_With_Trace (Standard_Parser, "", Trace_Output));
      Check ("8.3 Trace records specific edge error message", Contains (To_String (Trace_Output), "Reject: Empty input"));

      -- TEST 9 - Invalid Single Character
      Put_Line ("TEST 9 - Invalid Input (Single)");
      Check ("9.1 'a' is incomplete", not Parse (Standard_Parser, "a"));
      Check ("9.2 Fails safely via relation engine", not Parse_With_Trace (Standard_Parser, "a", Trace_Output));
      Check ("9.3 Trace catches no relation failure", Contains (To_String (Trace_Output), "No precedence relation"));

      -- TEST 10 - Incomplete Strings
      Put_Line ("TEST 10 - Invalid Input (Incomplete sequence)");
      Check ("10.1 'ac' fails", not Parse (Standard_Parser, "ac"));
      Check ("10.2 'cb' fails", not Parse (Standard_Parser, "cb"));
      Check ("10.3 Incomplete parsing properly logged", not Parse_With_Trace (Standard_Parser, "ac", Trace_Output));

      -- TEST 11 - Superfluous Characters
      Put_Line ("TEST 11 - Invalid Input (Extra Characters)");
      Check ("11.1 'acbc' fails", not Parse (Standard_Parser, "acbc"));
      Check ("11.2 Trace failure confirmed", not Parse_With_Trace (Standard_Parser, "acbc", Trace_Output));
      Check ("11.3 Failed state traced to bad adjacency", Contains (To_String (Trace_Output), "No precedence relation"));

      -- TEST 12 - Totally Unknown Character Input
      Put_Line ("TEST 12 - Invalid Input (Unknown Terminals)");
      Check ("12.1 'x' instantly fails", not Parse (Standard_Parser, "x"));
      Check ("12.2 'axb' fails midway", not Parse (Standard_Parser, "axb"));
      Check ("12.3 Correct error identified", not Parse_With_Trace (Standard_Parser, "x", Trace_Output));
      Check ("12.4 Valid trace detail for unknown char", Contains (To_String (Trace_Output), "No precedence relation"));
   end;

   -- TEST 13 - Malformed Stack Sequence
   declare
      Broken_Prods : constant Production_Array :=
        [1 => (LHS => 'S', RHS => To_Unbounded_String ("x"))];
   begin
      -- Assign matrix values beforehand
      Broken_Matrix ('$', 'x') := Equal; -- Notice: 'Equal' instead of 'Takes'
      Broken_Matrix ('x', '$') := Yields;
      
      -- Create parser initialized safely as a constant in an inner scope
      declare
         Broken_Parser : constant Parser := Create_Parser ('S', Broken_Prods, Broken_Matrix);
      begin
         Put_Line ("TEST 13 - Malformed Stack Sequence (Internal Handle Recovery)");
         Check ("13.1 Parse rejects gracefully", not Parse (Broken_Parser, "x"));
         Check ("13.2 Trace fails cleanly", not Parse_With_Trace (Broken_Parser, "x", Trace_Output));
         Check ("13.3 Handle start exception triggers exactly", Contains (To_String (Trace_Output), "Could not find handle start"));
      end;
   end;

   -- TEST 14 - Invalid Input with Handle Missing Production Rule
   declare
      Missing_RHS_Prods : constant Production_Array := 
        [1 => (LHS => 'S', RHS => To_Unbounded_String ("y"))]; -- Production is y, not x
   begin
      -- Matrix sets x as a valid handle, but no rule matches x.
      Broken_Matrix ('$', 'x') := Takes;
      Broken_Matrix ('x', '$') := Yields;
      
      declare
         Missing_Parser : constant Parser := Create_Parser ('S', Missing_RHS_Prods, Broken_Matrix);
      begin
         Put_Line ("TEST 14 - Production Mismatch");
         Check ("14.1 Parse fails when no matching production RHS is found", not Parse (Missing_Parser, "x"));
         Check ("14.2 Trace variant fails consistently", not Parse_With_Trace (Missing_Parser, "x", Trace_Output));
         Check ("14.3 Trace pinpoints missing production", Contains (To_String (Trace_Output), "No production for handle x"));
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
