with Ada.Text_IO; use Ada.Text_IO;
with Gray_Code;   use Gray_Code;

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

   -- Helper procedures to evaluate functions in the statement block
   -- without needing to declare dynamically sized dummy variables.
   procedure Discard_String (S : String) is
      pragma Unreferenced (S);
   begin
      null;
   end Discard_String;

   procedure Discard_Digits (D : Digit_Array) is
      pragma Unreferenced (D);
   begin
      null;
   end Discard_Digits;

begin
   Put_Line ("TEST 1 — Binary_To_Gray (Basic)");
   Check ("1.1 B2G(0)=0", Binary_To_Gray(0) = 0);
   Check ("1.2 B2G(1)=1", Binary_To_Gray(1) = 1);
   Check ("1.3 B2G(2)=3", Binary_To_Gray(2) = 3);

   Put_Line ("TEST 2 — Binary_To_Gray (Powers of 2)");
   Check ("2.1 B2G(4)=6",  Binary_To_Gray(4) = 6);
   Check ("2.2 B2G(8)=12", Binary_To_Gray(8) = 12);
   Check ("2.3 B2G(16)=24", Binary_To_Gray(16) = 24);

   Put_Line ("TEST 3 — Gray_To_Binary (Basic)");
   Check ("3.1 G2B(0)=0", Gray_To_Binary(0) = 0);
   Check ("3.2 G2B(1)=1", Gray_To_Binary(1) = 1);
   Check ("3.3 G2B(3)=2", Gray_To_Binary(3) = 2);

   Put_Line ("TEST 4 — Gray_To_Binary (Powers of 2)");
   Check ("4.1 G2B(6)=4",  Gray_To_Binary(6) = 4);
   Check ("4.2 G2B(12)=8", Gray_To_Binary(12) = 8);
   Check ("4.3 G2B(24)=16", Gray_To_Binary(24) = 16);

   Put_Line ("TEST 5 — Round Trips");
   Check ("5.1 RoundTrip 42", Gray_To_Binary(Binary_To_Gray(42)) = 42);
   Check ("5.2 RoundTrip 1337", Gray_To_Binary(Binary_To_Gray(1337)) = 1337);
   Check ("5.3 RoundTrip 99999", Gray_To_Binary(Binary_To_Gray(99999)) = 99999);

   Put_Line ("TEST 6 — Binary_String_To_Gray");
   Check ("6.1 BSTG 011 -> 010", Binary_String_To_Gray("011") = "010");
   Check ("6.2 BSTG 100 -> 110", Binary_String_To_Gray("100") = "110");
   Check ("6.3 BSTG 111 -> 100", Binary_String_To_Gray("111") = "100");

   Put_Line ("TEST 7 — Gray_String_To_Binary");
   Check ("7.1 GSTB 010 -> 011", Gray_String_To_Binary("010") = "011");
   Check ("7.2 GSTB 110 -> 100", Gray_String_To_Binary("110") = "100");
   Check ("7.3 GSTB 100 -> 111", Gray_String_To_Binary("100") = "111");

   Put_Line ("TEST 8 — String Conversion Exceptions");
   begin
      Discard_String (Binary_String_To_Gray("102"));
      Check ("8.1 BSTG Invalid char", False);
   exception
      when Invalid_String => Check ("8.1 BSTG Invalid char", True);
   end;
   begin
      Discard_String (Gray_String_To_Binary("abc"));
      Check ("8.2 GSTB Invalid char", False);
   exception
      when Invalid_String => Check ("8.2 GSTB Invalid char", True);
   end;
   begin
      Discard_String (Binary_String_To_Gray(""));
      Check ("8.3 BSTG Empty string", False);
   exception
      when Empty_Constraint => Check ("8.3 BSTG Empty string", True);
   end;

   Put_Line ("TEST 9 — Generate_BRGC (Lengths and Content)");
   declare
      S1 : constant Word_Array := Generate_BRGC(1);
      S3 : constant Word_Array := Generate_BRGC(3);
   begin
      Check ("9.1 Gen length 1 (2^1)", S1'Length = 2);
      Check ("9.2 Gen length 3 (2^3)", S3'Length = 8);
      Check ("9.3 Seq3(First) is 0", S3(S3'First) = 0);
   end;

   Put_Line ("TEST 10 — Generate_BRGC (Validity)");
   Check ("10.1 Valid seq 2", Is_Valid_Gray_Sequence(Generate_BRGC(2)));
   Check ("10.2 Valid seq 4", Is_Valid_Gray_Sequence(Generate_BRGC(4)));
   Check ("10.3 Valid seq 8", Is_Valid_Gray_Sequence(Generate_BRGC(8)));

   Put_Line ("TEST 11 — N_Ary_To_Gray (Base 3)");
   Check ("11.1 N2G 02 -> 02", N_Ary_To_Gray(Digit_Array'(1=>0, 2=>2), 3) = Digit_Array'(1=>0, 2=>2));
   Check ("11.2 N2G 10 -> 12", N_Ary_To_Gray(Digit_Array'(1=>1, 2=>0), 3) = Digit_Array'(1=>1, 2=>2));
   Check ("11.3 N2G 11 -> 11", N_Ary_To_Gray(Digit_Array'(1=>1, 2=>1), 3) = Digit_Array'(1=>1, 2=>1));

   Put_Line ("TEST 12 — Gray_To_N_Ary (Base 3)");
   Check ("12.1 G2N 02 -> 02", Gray_To_N_Ary(Digit_Array'(1=>0, 2=>2), 3) = Digit_Array'(1=>0, 2=>2));
   Check ("12.2 G2N 12 -> 10", Gray_To_N_Ary(Digit_Array'(1=>1, 2=>2), 3) = Digit_Array'(1=>1, 2=>0));
   Check ("12.3 G2N 11 -> 11", Gray_To_N_Ary(Digit_Array'(1=>1, 2=>1), 3) = Digit_Array'(1=>1, 2=>1));

   Put_Line ("TEST 13 — Sequence Validation Logic");
   declare
      Bad1 : constant Word_Array := Word_Array'(1=>0, 2=>3);
      Bad2 : constant Word_Array := Word_Array'(1=>0, 2=>0);
      Good : constant Word_Array := Word_Array'(1=>0);
   begin
      Check ("13.1 Invalid step 0->3", not Is_Valid_Gray_Sequence(Bad1));
      Check ("13.2 Invalid step 0->0", not Is_Valid_Gray_Sequence(Bad2));
      Check ("13.3 Valid single-elem", Is_Valid_Gray_Sequence(Good));
   end;
   
   Put_Line ("TEST 14 — N_Ary Exceptions");
   begin
      Discard_Digits (N_Ary_To_Gray (Digit_Array'(1 => 5), 3));
      Check ("14.1 Invalid digit bounds", False);
   exception
      when Invalid_Digit => Check ("14.1 Invalid digit bounds", True);
   end;
   begin
      Discard_Digits (Gray_To_N_Ary (Digit_Array'(1 => 3), 3));
      Check ("14.2 Invalid digit bounds (Gray)", False);
   exception
      when Invalid_Digit => Check ("14.2 Invalid digit bounds (Gray)", True);
   end;
   begin
      Discard_Digits (N_Ary_To_Gray (Digit_Array'(1 .. 0 => 0), 3));
      Check ("14.3 Empty digit array", False);
   exception
      when Empty_Constraint => Check ("14.3 Empty digit array", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
