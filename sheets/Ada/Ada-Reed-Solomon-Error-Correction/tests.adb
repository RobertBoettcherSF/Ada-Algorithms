with Ada.Text_IO; use Ada.Text_IO;
with Reed_Solomon; use Reed_Solomon;

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

   Msg_Data : constant Polynomial := [10, 20, 30];
   ECC_Len  : constant Natural := 4;

begin
   -- TEST 1 — GF Addition (XOR in GF(2^8))
   Put_Line ("TEST 1 — GF Addition");
   Check ("1.1 Identical sum is zero", (Symbol'(45) + Symbol'(45)) = 0);
   Check ("1.2 0 acts as identity", (Symbol'(23) + Symbol'(0)) = 23);
   Check ("1.3 Commutative property", (Symbol'(12) + Symbol'(34)) = (Symbol'(34) + Symbol'(12)));

   -- TEST 2 — GF Multiplication
   Put_Line ("TEST 2 — GF Multiplication");
   Check ("2.1 Mult by 0 is 0", (Symbol'(255) * Symbol'(0)) = 0);
   Check ("2.2 Mult by 1 is identity", (Symbol'(144) * Symbol'(1)) = 144);
   Check ("2.3 Complex Mult (3*4=12 in GF)", (Symbol'(3) * Symbol'(4)) = 12);

   -- TEST 3 — GF Division
   Put_Line ("TEST 3 — GF Division");
   Check ("3.1 Div by self is 1", (Symbol'(99) / Symbol'(99)) = 1);
   Check ("3.2 Zero dividend is zero", (Symbol'(0) / Symbol'(88)) = 0);
   Check ("3.3 Inverse mult relation", ((Symbol'(7) * Symbol'(13)) / Symbol'(13)) = 7);

   -- TEST 4 — Polynomial Addition
   Put_Line ("TEST 4 — Polynomial Addition");
   declare
      P1 : constant Polynomial := [1, 2, 3];
      P2 : constant Polynomial := [1, 5, 0, 4];
      P3 : constant Polynomial := Poly_Add (P1, P2);
   begin
      Check ("4.1 Length matched max", P3'Length = 4);
      Check ("4.2 Add overlapping", P3(1) = (Symbol'(2) + Symbol'(5)));
      Check ("4.3 Extended terms unharmed", P3(3) = 4);
   end;

   -- TEST 5 — Polynomial Multiplication
   Put_Line ("TEST 5 — Polynomial Multiplication");
   declare
      P1 : constant Polynomial := [1, 2];
      P2 : constant Polynomial := [3, 4];
      P3 : constant Polynomial := Poly_Mult (P1, P2);
   begin
      Check ("5.1 Deg 1 * Deg 1 is Deg 2", P3'Length = 3);
      Check ("5.2 First term (1*3)", P3(0) = 3);
      Check ("5.3 Middle term combo", P3(1) = ((Symbol'(1)*Symbol'(4)) + (Symbol'(2)*Symbol'(3))));
   end;

   -- TEST 6 — Polynomial Evaluation
   Put_Line ("TEST 6 — Polynomial Evaluation");
   declare
      P : constant Polynomial := [10, 20, 30];
   begin
      Check ("6.1 Eval at 0 is const term", Poly_Eval(P, 0) = 10);
      Check ("6.2 Eval at 1 is sum", Poly_Eval(P, 1) = (10 + 20 + 30));
      Check ("6.3 Eval identity relation", Poly_Eval([0=>5], 99) = 5);
   end;

   -- TEST 7 — Original View Encoding
   Put_Line ("TEST 7 — Original View Encoding");
   declare
      O_Msg : constant Polynomial := [1, 2, 3];
      O_CW  : constant Polynomial := Encode_Original_View (O_Msg, 5);
   begin
      Check ("7.1 Codeword length is N", O_CW'Length = 5);
      Check ("7.2 CW(0) = P(alpha^0)", O_CW(0) = Poly_Eval(O_Msg, 1));
      Check ("7.3 CW(1) = P(alpha^1)", O_CW(1) = Poly_Eval(O_Msg, 2));
   end;

   -- TEST 8 — BCH Generator Polynomial Construction
   Put_Line ("TEST 8 — BCH Generator Poly");
   declare
      G : constant Polynomial := Generate_Polynomial (2);
   begin
      Check ("8.1 G length is ECC+1", G'Length = 3);
      -- Roots are alpha^0 (1) and alpha^1 (2). G(x) = (x-1)(x-2) = x^2 + 3x + 2
      Check ("8.2 Highest term is 1", G(2) = 1);
      Check ("8.3 Middle term check", G(1) = 3);
   end;

   -- TEST 9 — BCH Systematic Encoding
   Put_Line ("TEST 9 — BCH Encoding Layout");
   declare
      CW : constant Polynomial := Encode_BCH (Msg_Data, ECC_Len);
   begin
      Check ("9.1 Length = Msg + ECC", CW'Length = Msg_Data'Length + ECC_Len);
      Check ("9.2 Systematic trait 1", CW(ECC_Len) = Msg_Data(0));
      Check ("9.3 Systematic trait 2", CW(CW'Last) = Msg_Data(Msg_Data'Last));
   end;

   -- TEST 10 — Syndrome Calculation
   Put_Line ("TEST 10 — Syndromes");
   declare
      CW : constant Polynomial := Encode_BCH (Msg_Data, ECC_Len);
      S  : constant Polynomial := Calculate_Syndromes (CW, ECC_Len);
      CW_Err : Polynomial := CW;
   begin
      Check ("10.1 Clean S(0) is 0", S(0) = 0);
      Check ("10.2 Clean S(1) is 0", S(1) = 0);
      CW_Err(0) := CW_Err(0) xor 123;
      declare
         S_Err : constant Polynomial := Calculate_Syndromes (CW_Err, ECC_Len);
      begin
         Check ("10.3 Corrupt syndrome non-zero", S_Err(0) /= 0);
      end;
   end;

   -- TEST 11 — BCH Decoding (Clean)
   Put_Line ("TEST 11 — Decode Clean");
   declare
      CW : constant Polynomial := Encode_BCH (Msg_Data, ECC_Len);
      Dec : constant Polynomial := Decode_BCH (CW, ECC_Len);
   begin
      Check ("11.1 Decode length matches msg", Dec'Length = Msg_Data'Length);
      Check ("11.2 Data match 0", Dec(0) = Msg_Data(0));
      Check ("11.3 Data match 2", Dec(2) = Msg_Data(2));
   end;

   -- TEST 12 — BCH Decoding (Correctable Errors)
   Put_Line ("TEST 12 — Decode with Max Corrections");
   declare
      CW_Err : Polynomial := Encode_BCH (Msg_Data, ECC_Len);
   begin
      -- Inject exactly 2 errors (Max for ECC=4)
      CW_Err(1) := CW_Err(1) xor 255;
      CW_Err(3) := CW_Err(3) xor 128;
      declare
         Dec : constant Polynomial := Decode_BCH (CW_Err, ECC_Len);
      begin
         Check ("12.1 Msg 0 recovered", Dec(0) = Msg_Data(0));
         Check ("12.2 Msg 1 recovered", Dec(1) = Msg_Data(1));
         Check ("12.3 Msg 2 recovered", Dec(2) = Msg_Data(2));
      end;
   end;

   -- TEST 13 — BCH Decoding (Uncorrectable Errors)
   Put_Line ("TEST 13 — Decode Failure Handling");
   declare
      CW_Err : Polynomial := Encode_BCH (Msg_Data, ECC_Len);
   begin
      -- Inject 3 errors (ECC=4 can only fix 2)
      CW_Err(0) := CW_Err(0) xor 1;
      CW_Err(1) := CW_Err(1) xor 2;
      CW_Err(2) := CW_Err(2) xor 3;
      
      begin
         declare
            Dec : constant Polynomial := Decode_BCH (CW_Err, ECC_Len);
            pragma Unreferenced (Dec);
         begin
            Check ("13.1 Exception expected", False);
         end;
      exception
         when Decoding_Error =>
            Check ("13.2 Correct exception raised", True);
            Check ("13.3 Graceful exit", True);
      end;
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
