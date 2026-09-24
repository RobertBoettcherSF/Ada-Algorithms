-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Shannon_Fano_Elias; use Shannon_Fano_Elias;

procedure Tests is
   Data_Empty : Symbol_Array (1 .. 0);
   Data_Valid : Symbol_Array (1 .. 3) := 
     ((1, 0.5, 0.0, 0.0, 1, Null_Unbounded_String),
      (2, 0.25, 0.0, 0.0, 1, Null_Unbounded_String),
      (3, 0.25, 0.0, 0.0, 1, Null_Unbounded_String));
      
   Data_Sum_Under : Symbol_Array (1 .. 2) :=
     ((1, 0.4, 0.0, 0.0, 1, Null_Unbounded_String),
      (2, 0.4, 0.0, 0.0, 1, Null_Unbounded_String));
      
   Data_Sum_Over : Symbol_Array (1 .. 2) :=
     ((1, 0.6, 0.0, 0.0, 1, Null_Unbounded_String),
      (2, 0.6, 0.0, 0.0, 1, Null_Unbounded_String));
      
   Data_Neg : Symbol_Array (1 .. 2) :=
     ((1, 0.0, 0.0, 0.0, 1, Null_Unbounded_String),
      (2, 1.0, 0.0, 0.0, 1, Null_Unbounded_String)); -- 0.0 violates strict > 0 rule

   -- Helper to check prefix property
   function Is_Prefix (S1, S2 : String) return Boolean is
   begin
      if S1'Length > S2'Length then return False; end if;
      return S2(S2'First .. S2'First + S1'Length - 1) = S1;
   end Is_Prefix;

begin
   Put_Line ("Starting Test Suite for Shannon-Fano-Elias Algorithm...");
   Put_Line ("Methodology: Assume codebase is fundamentally broken. Disprove to PASS.");
   Put_Line ("------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Empty Input Handling");
   Put_Line ("  1.1 Assume code crashes catastrophically on empty arrays.");
   begin
      Encode (Data_Empty);
      Put_Line ("      FAIL: Allowed empty input without exception.");
   exception
      when Empty_Input =>
         Put_Line ("      PASS: Correctly isolated and rejected empty input. Assumption disproven.");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Zero Probability Rejection");
   Put_Line ("  2.1 Assume code calculates Math.Log(0) and panics.");
   begin
      Encode (Data_Neg);
      Put_Line ("      FAIL: Allowed 0.0 probability.");
   exception
      when Invalid_Distribution =>
         Put_Line ("      PASS: Caught 0.0 probability cleanly. Assumption disproven.");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Probability Sum < 1.0");
   Put_Line ("  3.1 Assume code generates invalid partial CDF models.");
   begin
      Encode (Data_Sum_Under);
      Put_Line ("      FAIL: Executed with sum = 0.8.");
   exception
      when Invalid_Distribution =>
         Put_Line ("      PASS: Strict summation validation enforced. Assumption disproven.");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Probability Sum > 1.0");
   Put_Line ("  4.1 Assume code overrides buffer sizes due to sum > 1.0.");
   begin
      Encode (Data_Sum_Over);
      Put_Line ("      FAIL: Executed with sum = 1.2.");
   exception
      when Invalid_Distribution =>
         Put_Line ("      PASS: Caught sum exceeding 1.0 constraint. Assumption disproven.");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Code Length Calculation (P = 0.5)");
   Put_Line ("  5.1 Assume ceil(-log2(x)) + 1 logic has off-by-one errors.");
   if Calculate_Length(0.5) = 2 then
      Put_Line ("      PASS: Length for P=0.5 is 2. Assumption disproven.");
   else
      Put_Line ("      FAIL: Length calculation incorrect.");
   end if;

   -- TEST 6
   Put_Line ("TEST 6 - Code Length Calculation (P = 0.25)");
   Put_Line ("  6.1 Assume logarithm base is incorrectly bound to natural log (e).");
   if Calculate_Length(0.25) = 3 then
      Put_Line ("      PASS: Length for P=0.25 is 3. Assumption disproven.");
   else
      Put_Line ("      FAIL: Length calculation incorrect for P=0.25.");
   end if;

   -- TEST 7
   Put_Line ("TEST 7 - Code Length Calculation (Boundary P = 0.75)");
   Put_Line ("  7.1 Assume fractional logs round downwards erroneously.");
   if Calculate_Length(0.75) = 2 then
      Put_Line ("      PASS: Length for P=0.75 correctly evaluates to 2. Assumption disproven.");
   else
      Put_Line ("      FAIL: Expected 2.");
   end if;

   -- TEST 8
   Put_Line ("TEST 8 - Binary Fraction Conversion (0.5, len=2)");
   Put_Line ("  8.1 Assume bit-shifting creates endianness or truncation failures.");
   if To_String(Float_To_Binary(0.5, 2)) = "10" then
      Put_Line ("      PASS: Correctly mapped 0.5 to '10'. Assumption disproven.");
   else
      Put_Line ("      FAIL: Binary translation failed.");
   end if;

   -- TEST 9
   Put_Line ("TEST 9 - Binary Fraction Conversion (0.625, len=3)");
   Put_Line ("  9.1 Assume subsequent bit evaluations drop precision.");
   if To_String(Float_To_Binary(0.625, 3)) = "101" then
      Put_Line ("      PASS: Correctly mapped 0.625 to '101'. Assumption disproven.");
   else
      Put_Line ("      FAIL: Precision lost in binary string.");
   end if;

   -- RUN ENCODE ON VALID DATA
   Encode(Data_Valid);

   -- TEST 10
   Put_Line ("TEST 10 - F_Bar Calculation Logic");
   Put_Line ("  10.1 Assume modified CDF adds full P(x) instead of P(x)/2.");
   if Data_Valid(1).F_Bar = 0.25 and Data_Valid(2).F_Bar = 0.625 then
      Put_Line ("      PASS: Modified CDF perfectly aligns with P(x)/2 offset. Assumption disproven.");
   else
      Put_Line ("      FAIL: Modified CDF mathematically invalid.");
   end if;

   -- TEST 11
   Put_Line ("TEST 11 - Expected Binary Outputs");
   Put_Line ("  11.1 Assume codes drift and do not match theoretical Wikipedia spec.");
   if To_String(Data_Valid(1).Code) = "01" and 
      To_String(Data_Valid(2).Code) = "101" and
      To_String(Data_Valid(3).Code) = "111" then
      Put_Line ("      PASS: Generated codes match theoretical '01', '101', '111'. Assumption disproven.");
   else
      Put_Line ("      FAIL: Code output drifted from theoretical spec.");
   end if;

   -- TEST 12
   Put_Line ("TEST 12 - Prefix-Free Verification (Uniquely Decodable)");
   Put_Line ("  12.1 Assume algorithm produces overlapping codes (ambiguous decoding).");
   declare
      Overlaps : Boolean := False;
   begin
      for I in Data_Valid'Range loop
         for J in Data_Valid'Range loop
            if I /= J then
               if Is_Prefix(To_String(Data_Valid(I).Code), To_String(Data_Valid(J).Code)) then
                  Overlaps := True;
               end if;
            end if;
         end loop;
      end loop;
      if not Overlaps then
         Put_Line ("      PASS: System proven Prefix-Free. Codes do not overlap. Assumption disproven.");
      else
         Put_Line ("      FAIL: Codes are not uniquely decodable.");
      end if;
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Kraft Inequality Verification");
   Put_Line ("  13.1 Assume sequence lengths violate information theory limits (sum(2^-l) > 1).");
   declare
      Kraft_Sum : Long_Float := 0.0;
   begin
      for I in Data_Valid'Range loop
         Kraft_Sum := Kraft_Sum + (2.0 ** (-Data_Valid(I).Length));
      end loop;
      if Kraft_Sum <= 1.0 then
         Put_Line ("      PASS: Kraft sum = " & Long_Float'Image(Kraft_Sum) & " <= 1.0. Assumption disproven.");
      else
         Put_Line ("      FAIL: Violated Kraft Inequality.");
      end if;
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL VERIFICATIONS COMPLETE.");
end Tests;
