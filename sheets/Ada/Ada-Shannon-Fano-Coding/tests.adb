with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Shannon_Fano; use Shannon_Fano;

procedure Tests is
   -- Helper variables
   Arr_2 : Symbol_Array (1 .. 2);
   Arr_3 : Symbol_Array (1 .. 3);
   Arr_1 : Symbol_Array (1 .. 1);
   Arr_0 : Symbol_Array (1 .. 0);
begin
   Put_Line ("=================================================");
   Put_Line (" SHANNON-FANO ALGORITHM VERIFICATION SUITE");
   Put_Line (" Assuming code is broken. Testing to disprove...");
   Put_Line ("=================================================");
   New_Line;

   -- TEST 1: Fano - Equal Probabilities
   Put_Line ("TEST 1 - Fano Method: Equal Probabilities");
   Arr_2 := (1 => ('A', 0.5, Null_Unbounded_String), 2 => ('B', 0.5, Null_Unbounded_String));
   Generate_Fano_Codes (Arr_2);
   Put_Line ("  1.1 Assert Symbol A gets 1 bit code");
   Assert (Length (Arr_2(1).Code) = 1, "Length of A code incorrect");
   Put_Line ("  1.2 Assert codes are distinct");
   Assert (Arr_2(1).Code /= Arr_2(2).Code, "Codes match!");
   Put_Line ("    PASS");

   -- TEST 2: Fano - 3 Symbols (Skewed)
   Put_Line ("TEST 2 - Fano Method: 3 Skewed Symbols (0.5, 0.25, 0.25)");
   Arr_3 := (1 => ('A', 0.5, Null_Unbounded_String), 2 => ('B', 0.25, Null_Unbounded_String), 3 => ('C', 0.25, Null_Unbounded_String));
   Generate_Fano_Codes (Arr_3);
   Put_Line ("  2.1 Assert most probable has shortest code");
   Assert (Length (Arr_3(1).Code) < Length (Arr_3(2).Code), "A should be shorter than B");
   Put_Line ("  2.2 Assert prefix-free property between A and B");
   Assert (To_String (Arr_3(2).Code)(1..1) /= To_String(Arr_3(1).Code), "Prefix code failure");
   Put_Line ("  2.3 Assert lower prob symbols have same length");
   Assert (Length (Arr_3(2).Code) = Length (Arr_3(3).Code), "B and C lengths differ");
   Put_Line ("    PASS");

   -- TEST 3: Fano - Empty Input
   Put_Line ("TEST 3 - Fano Method: Empty Input Array");
   Put_Line ("  3.1 Assert Empty_Input is raised");
   begin
      Generate_Fano_Codes (Arr_0);
      Assert (False, "Exception Empty_Input not raised");
   exception
      when Empty_Input => Put_Line ("    PASS");
   end;

   -- TEST 4: Fano - Single Element
   Put_Line ("TEST 4 - Fano Method: Single Element");
   Arr_1 := (1 => ('A', 1.0, Null_Unbounded_String));
   Generate_Fano_Codes (Arr_1);
   Put_Line ("  4.1 Assert code evaluates to '0' seamlessly");
   Assert (To_String (Arr_1(1).Code) = "0", "Single element failed");
   Put_Line ("    PASS");

   -- TEST 5: Fano - Zero Probability
   Put_Line ("TEST 5 - Fano Method: Zero Probability Filtering");
   Arr_2 := (1 => ('A', 0.0, Null_Unbounded_String), 2 => ('B', 1.0, Null_Unbounded_String));
   Put_Line ("  5.1 Assert Invalid_Probability is raised for 0.0");
   begin
      Generate_Fano_Codes (Arr_2);
      Assert (False, "Invalid_Probability not raised");
   exception
      when Invalid_Probability => Put_Line ("    PASS");
   end;

   -- TEST 6: Fano - Negative Probability
   Put_Line ("TEST 6 - Fano Method: Negative Probability Boundaries");
   Arr_2 := (1 => ('A', -0.5, Null_Unbounded_String), 2 => ('B', 1.5, Null_Unbounded_String));
   Put_Line ("  6.1 Assert Invalid_Probability is raised for negative weight");
   begin
      Generate_Fano_Codes (Arr_2);
      Assert (False, "Invalid_Probability not raised");
   exception
      when Invalid_Probability => Put_Line ("    PASS");
   end;

   -- TEST 7: Shannon - Basic Equal Probabilities
   Put_Line ("TEST 7 - Shannon Method: Equal Probabilities");
   Arr_2 := (1 => ('A', 0.5, Null_Unbounded_String), 2 => ('B', 0.5, Null_Unbounded_String));
   Generate_Shannon_Codes (Arr_2);
   Put_Line ("  7.1 Assert symbol A code length is 1 (ceil(-log2(0.5)))");
   Assert (Length(Arr_2(1).Code) = 1, "Length should be exactly 1");
   Put_Line ("  7.2 Assert codes are deterministic prefixes");
   Assert (Arr_2(1).Code /= Arr_2(2).Code, "Codes match!");
   Put_Line ("    PASS");

   -- TEST 8: Shannon - Skewed Logarithmic Lengths
   Put_Line ("TEST 8 - Shannon Method: Skewed Logarithmic Lengths");
   Arr_3 := (1 => ('A', 0.5, Null_Unbounded_String), 2 => ('B', 0.25, Null_Unbounded_String), 3 => ('C', 0.25, Null_Unbounded_String));
   Generate_Shannon_Codes (Arr_3);
   Put_Line ("  8.1 Assert symbol A uses 1 bit (-log2(0.5))");
   Assert (Length (Arr_3(1).Code) = 1, "A length not 1");
   Put_Line ("  8.2 Assert symbol C uses 2 bits (-log2(0.25))");
   Assert (Length (Arr_3(3).Code) = 2, "C length not 2");
   Put_Line ("    PASS");

   -- TEST 9: Shannon - Empty Input Exception
   Put_Line ("TEST 9 - Shannon Method: Empty Input Array");
   Put_Line ("  9.1 Assert Empty_Input is raised");
   begin
      Generate_Shannon_Codes (Arr_0);
      Assert (False, "Exception Empty_Input not raised");
   exception
      when Empty_Input => Put_Line ("    PASS");
   end;

   -- TEST 10: Shannon - Invalid Probability Exception
   Put_Line ("TEST 10 - Shannon Method: Zero Probability Filtering");
   Arr_2 := (1 => ('A', 0.0, Null_Unbounded_String), 2 => ('B', 1.0, Null_Unbounded_String));
   Put_Line ("  10.1 Assert Invalid_Probability is raised");
   begin
      Generate_Shannon_Codes (Arr_2);
      Assert (False, "Invalid_Probability not raised");
   exception
      when Invalid_Probability => Put_Line ("    PASS");
   end;

   -- TEST 11: System - Fano Sort Unsorted Data
   Put_Line ("TEST 11 - Fano Method: Internal Sorting Integrity");
   Arr_3 := (1 => ('B', 0.1, Null_Unbounded_String), 2 => ('A', 0.8, Null_Unbounded_String), 3 => ('C', 0.1, Null_Unbounded_String));
   Generate_Fano_Codes (Arr_3);
   Put_Line ("  11.1 Assert array is implicitly sorted by prob descending");
   Assert (Arr_3(1).Symbol = 'A', "A should be first");
   Put_Line ("  11.2 Assert correct code assigned after sort");
   Assert (Length(Arr_3(1).Code) < Length(Arr_3(3).Code), "A code length incorrect");
   Put_Line ("    PASS");

   -- TEST 12: System - Shannon Sort Unsorted Data
   Put_Line ("TEST 12 - Shannon Method: Internal Sorting Integrity");
   Arr_3 := (1 => ('C', 0.125, Null_Unbounded_String), 2 => ('A', 0.75, Null_Unbounded_String), 3 => ('B', 0.125, Null_Unbounded_String));
   Generate_Shannon_Codes (Arr_3);
   Put_Line ("  12.1 Assert array sorted correctly");
   Assert (Arr_3(1).Symbol = 'A', "A should be first");
   Put_Line ("    PASS");

   -- TEST 13: System - Normalization Math
   Put_Line ("TEST 13 - System: Non-Normalized Data (Sum > 1.0)");
   Arr_2 := (1 => ('A', 10.0, Null_Unbounded_String), 2 => ('B', 10.0, Null_Unbounded_String));
   Generate_Fano_Codes (Arr_2);
   Put_Line ("  13.1 Assert algorithm normalizes weights seamlessly");
   Assert (Arr_2(1).Probability = 0.5, "Probability A not normalized");
   Put_Line ("  13.2 Assert normalization keeps equality");
   Assert (Arr_2(2).Probability = 0.5, "Probability B not normalized");
   Put_Line ("    PASS");

   New_Line;
   Put_Line ("=================================================");
   Put_Line (" ALL 13 ASSUMPTIONS DISPROVEN. CODE IS CORRECT.");
   Put_Line ("=================================================");
end Tests;
