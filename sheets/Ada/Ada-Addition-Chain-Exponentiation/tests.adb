--  Standalone test suite for Addition_Chain_Exponentiation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Addition_Chain_Exponentiation; use Addition_Chain_Exponentiation;

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

   function Max_SN return Positive is (Max_Shortest_N);
   function Max_NE return Natural is (Max_Naive_Exp);

   function Raised_Invalid (Op : access procedure) return Boolean is
   begin
      Op.all;
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

   --  OEIS A003313 for n = 1 .. 32 (length = multiplication count).
   A003313 : constant array (1 .. 32) of Natural :=
     [0, 1, 2, 2, 3, 3, 4, 3, 4, 4, 5, 4, 5, 5, 5, 4,
      5, 5, 6, 5, 6, 6, 6, 5, 6, 6, 6, 6, 7, 6, 7, 5];

begin
   Ada.Text_IO.Put_Line ("Addition_Chain_Exponentiation test suite");
   Ada.Text_IO.Put_Line ("========================================");

   ------------------------------------------------------------------
   Section ("1. Bounds and Binary_Mul_Count");
   ------------------------------------------------------------------
   Check (Max_SN = 32, "Max_Shortest_N=32");
   Check (Max_NE = 10_000, "Max_Naive_Exp=10000");
   Check (Binary_Mul_Count (1) = 0, "binary muls 1 = 0");
   Check (Binary_Mul_Count (2) = 1, "binary muls 2 = 1");
   Check (Binary_Mul_Count (3) = 2, "binary muls 3 = 2");
   Check (Binary_Mul_Count (15) = 6, "binary muls 15 = 6");
   Check (Binary_Mul_Count (31) = 8, "binary muls 31 = 8");
   Check (Binary_Mul_Count (16) = 4, "binary muls 16 = 4");
   Check (Binary_Mul_Count (7) = 4, "binary muls 7 = 4");
   Check (Binary_Mul_Count (32) = 5, "binary muls 32 = 5");

   ------------------------------------------------------------------
   Section ("2. Is_Valid_Chain: valid examples");
   ------------------------------------------------------------------
   declare
      C15 : Chain;
      C31 : Chain;
      C1  : Chain;
      C2  : Chain;
   begin
      C1.Last := 0;
      C1.Elements (0) := 1;
      Check (Is_Valid_Chain (C1), "valid [1]");

      C2.Last := 1;
      C2.Elements (0) := 1;
      C2.Elements (1) := 2;
      Check (Is_Valid_Chain (C2), "valid [1,2]");

      --  Classic shortest for 15: 1,2,3,6,12,15
      C15.Last := 5;
      C15.Elements (0) := 1;
      C15.Elements (1) := 2;
      C15.Elements (2) := 3;
      C15.Elements (3) := 6;
      C15.Elements (4) := 12;
      C15.Elements (5) := 15;
      Check (Is_Valid_Chain (C15), "valid [1,2,3,6,12,15]");
      Check (Chain_Mul_Count (C15) = 5, "15-chain mul count = 5");
      Check (Chain_Exponent (C15) = 15, "15-chain exponent = 15");

      --  Alternate shortest: 1,2,3,5,10,15
      C15.Elements (3) := 5;
      C15.Elements (4) := 10;
      C15.Elements (5) := 15;
      Check (Is_Valid_Chain (C15), "valid [1,2,3,5,10,15]");
      Check (Chain_Mul_Count (C15) = 5, "alt 15-chain muls = 5");

      --  31-chain from wiki: 1,2,3,6,12,24,30,31
      C31.Last := 7;
      C31.Elements (0) := 1;
      C31.Elements (1) := 2;
      C31.Elements (2) := 3;
      C31.Elements (3) := 6;
      C31.Elements (4) := 12;
      C31.Elements (5) := 24;
      C31.Elements (6) := 30;
      C31.Elements (7) := 31;
      Check (Is_Valid_Chain (C31), "valid [1,2,3,6,12,24,30,31]");
      Check (Chain_Mul_Count (C31) = 7, "31-chain muls = 7");
   end;

   ------------------------------------------------------------------
   Section ("3. Is_Valid_Chain: invalid examples");
   ------------------------------------------------------------------
   declare
      Bad : Chain;
   begin
      Bad.Last := 1;
      Bad.Elements (0) := 2;
      Bad.Elements (1) := 3;
      Check (not Is_Valid_Chain (Bad), "invalid: does not start at 1");

      Bad.Last := 2;
      Bad.Elements (0) := 1;
      Bad.Elements (1) := 2;
      Bad.Elements (2) := 5;  -- 5 is not 2+2 or 2+1
      Check (not Is_Valid_Chain (Bad), "invalid: 5 not sum of prior");

      Bad.Last := 2;
      Bad.Elements (0) := 1;
      Bad.Elements (1) := 3;
      Bad.Elements (2) := 4;
      Check (not Is_Valid_Chain (Bad), "invalid: 3 not sum (missing 2)");

      Bad.Last := 2;
      Bad.Elements (0) := 1;
      Bad.Elements (1) := 2;
      Bad.Elements (2) := 2;  -- not strictly increasing
      Check (not Is_Valid_Chain (Bad), "invalid: not strictly increasing");

      Bad.Last := 3;
      Bad.Elements (0) := 1;
      Bad.Elements (1) := 2;
      Bad.Elements (2) := 4;
      Bad.Elements (3) := 3;  -- decreasing
      Check (not Is_Valid_Chain (Bad), "invalid: decreasing step");
   end;

   ------------------------------------------------------------------
   Section ("4. Build_Binary_Chain");
   ------------------------------------------------------------------
   declare
      B15 : constant Chain := Build_Binary_Chain (15);
      B1  : constant Chain := Build_Binary_Chain (1);
      B2  : constant Chain := Build_Binary_Chain (2);
      B8  : constant Chain := Build_Binary_Chain (8);
      B31 : constant Chain := Build_Binary_Chain (31);
   begin
      Check (Is_Valid_Chain (B15)
             and then Chain_Exponent (B15) = 15
             and then Chain_Mul_Count (B15) = 6,
             "binary chain 15 valid length 6");
      Check (Chain_Mul_Count (B8) = 3, "binary chain 8 length 3");
      Check (Chain_Mul_Count (B1) = 0 and then Chain_Mul_Count (B2) = 1,
             "binary chains 1 and 2 lengths");
      Check (Chain_Mul_Count (B31) = Binary_Mul_Count (31),
             "binary chain 31 len = Binary_Mul_Count");
   end;

   declare
      Sample : constant array (Positive range <>) of Positive :=
        [1, 2, 3, 7, 8, 15, 16, 23, 27, 31, 32];
   begin
      for N of Sample loop
         declare
            C : constant Chain := Build_Binary_Chain (N);
         begin
            Check (Is_Valid_Chain (C)
                   and then Chain_Exponent (C) = N
                   and then Chain_Mul_Count (C) = Binary_Mul_Count (N),
                   "binary chain ok for n=" & N'Image);
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("5. Shortest_Chain_Length vs OEIS A003313");
   ------------------------------------------------------------------
   for N in 1 .. 32 loop
      Check (Shortest_Chain_Length (N) = A003313 (N),
             "shortest len n=" & N'Image & " = A003313");
   end loop;
   Check (Shortest_Chain_Length (15) < Binary_Mul_Count (15),
          "shortest(15) < binary(15)");
   Check (Shortest_Chain_Length (23) < Binary_Mul_Count (23),
          "shortest(23) < binary(23)");

   ------------------------------------------------------------------
   Section ("6. Build_Shortest_Chain");
   ------------------------------------------------------------------
   declare
      Sample : constant array (Positive range <>) of Positive :=
        [1, 2, 5, 15, 23, 27, 30, 31, 32];
   begin
      for N of Sample loop
         declare
            C : constant Chain := Build_Shortest_Chain (N);
         begin
            Check (Is_Valid_Chain (C)
                   and then Chain_Exponent (C) = N
                   and then Chain_Mul_Count (C) = A003313 (N),
                   "shortest chain ok n=" & N'Image);
         end;
      end loop;
   end;

   declare
      S15 : constant Chain := Build_Shortest_Chain (15);
   begin
      Check (Chain_Mul_Count (S15) <= 6, "15-chain ≤6 muls");
      Check (Chain_Mul_Count (S15) = 5, "15 shortest = 5 muls");
      Check (Chain_Mul_Count (S15) < Binary_Mul_Count (15),
             "15 shortest beats binary 6");
   end;

   ------------------------------------------------------------------
   Section ("7. Evaluate_Chain / Power_By_Chain match naive & binary");
   ------------------------------------------------------------------
   declare
      C15 : constant Chain := Build_Shortest_Chain (15);
      C_Bin : constant Chain := Build_Binary_Chain (15);
   begin
      Check (Evaluate_Chain (2, C15) = 32768, "2^15 via shortest=32768");
      Check (Evaluate_Chain (2, C_Bin) = 32768, "2^15 via binary chain");
      Check (Power_By_Chain (2, 15) = 32768, "Power_By_Chain 2^15");
      Check (Power_By_Shortest_Chain (2, 15) = 32768,
             "Power_By_Shortest 2^15");
      Check (Power_Binary (2, 15) = 32768, "Power_Binary 2^15");
      Check (Power_Naive (2, 15) = 32768, "Power_Naive 2^15");
   end;

   Check (Power_By_Chain (3, 5) = 243, "3^5=243 by chain");
   Check (Power_By_Chain (-2, 5) = -32, "(-2)^5 by chain");
   Check (Power_By_Chain (-2, 4) = 16, "(-2)^4 by chain");
   Check (Power_By_Shortest_Chain (3, 7) = 2187, "3^7 shortest");
   Check (Power_By_Shortest_Chain (-3, 3) = -27, "(-3)^3 shortest");

   declare
      Twos : constant array (Positive range <>) of Positive :=
        [1, 2, 5, 8, 10, 15];
      Threes : constant array (Positive range <>) of Positive :=
        [1, 3, 5, 7];
   begin
      for N of Twos loop
         declare
            B : constant Long_Integer := 2;
            Pc : constant Long_Integer := Power_By_Chain (B, N);
            Ps : constant Long_Integer := Power_By_Shortest_Chain (B, N);
            Pb : constant Long_Integer := Power_Binary (B, N);
            Pn : constant Long_Integer := Power_Naive (B, N);
         begin
            Check (Pc = Ps and then Ps = Pb and then Pb = Pn,
                   "2^n agree n=" & N'Image);
         end;
      end loop;
      for N of Threes loop
         declare
            B : constant Long_Integer := 3;
         begin
            Check (Power_By_Chain (B, N) = Power_Naive (B, N)
                   and then Power_By_Shortest_Chain (B, N) = Power_Naive (B, N),
                   "3^n agree n=" & N'Image);
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("8. Modular Evaluate / Pow_Mod agreement");
   ------------------------------------------------------------------
   declare
      M : constant Long_Integer := 1_000_000_007;
   begin
      Check (Evaluate_Chain_Mod (2, M, Build_Shortest_Chain (15))
             = Pow_Mod (2, 15, M),
             "2^15 mod M shortest = Pow_Mod");
      Check (Evaluate_Chain_Mod (2, M, Build_Binary_Chain (15))
             = Pow_Mod (2, 15, M),
             "2^15 mod M binary chain = Pow_Mod");
      Check (Power_By_Chain_Mod (3, 20, M) = Pow_Mod (3, 20, M),
             "3^20 mod M Power_By_Chain_Mod");
      Check (Power_By_Shortest_Chain_Mod (5, 31, M) = Pow_Mod (5, 31, M),
             "5^31 mod M shortest");
      Check (Pow_Mod (0, 0, 17) = 1, "0^0 mod 17 = 1");
      Check (Pow_Mod (0, 5, 17) = 0, "0^5 mod 17 = 0");
      Check (Mod_Mul (7, 15, 17) = 3, "7*15 mod 17 = 3");
      Check (Mod_Nonneg (-1, 5) = 4, "Mod_Nonneg -1 mod 5");
   end;

   declare
      M : constant Long_Integer := 97;
      B : constant Long_Integer := 11;
      Sample : constant array (Positive range <>) of Positive :=
        [1, 2, 3, 7, 15, 16, 23, 27, 31, 32];
   begin
      for N of Sample loop
         Check (Power_By_Chain_Mod (B, Long_Integer (N), M)
                = Pow_Mod (B, Long_Integer (N), M),
                "chain-mod = Pow_Mod n=" & N'Image);
         Check (Power_By_Shortest_Chain_Mod (B, Long_Integer (N), M)
                = Pow_Mod (B, Long_Integer (N), M),
                "shortest-mod = Pow_Mod n=" & N'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. 15-chain pedagogy: 5 vs binary 6");
   ------------------------------------------------------------------
   declare
      Short_C : constant Chain := Build_Shortest_Chain (15);
      Bin_C   : constant Chain := Build_Binary_Chain (15);
      Wiki_C  : Chain;
   begin
      Wiki_C.Last := 5;
      Wiki_C.Elements (0) := 1;
      Wiki_C.Elements (1) := 2;
      Wiki_C.Elements (2) := 3;
      Wiki_C.Elements (3) := 6;
      Wiki_C.Elements (4) := 12;
      Wiki_C.Elements (5) := 15;
      Check (Chain_Mul_Count (Short_C) = 5, "shortest 15 uses 5 muls");
      Check (Chain_Mul_Count (Bin_C) = 6, "binary 15 uses 6 muls");
      Check (Chain_Mul_Count (Wiki_C) = 5, "wiki 15-chain uses 5 muls");
      Check (Evaluate_Chain (2, Wiki_C) = Power_Binary (2, 15),
             "wiki chain eval = binary power");
      Check (Evaluate_Chain (2, Short_C) = Evaluate_Chain (2, Bin_C),
             "shortest and binary chains same power");
   end;

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument");
   ------------------------------------------------------------------
   declare
      procedure Bad_Shortest is
         L : Natural;
      begin
         L := Shortest_Chain_Length (33);
         pragma Unreferenced (L);
      end Bad_Shortest;

      procedure Bad_Build_S is
         C : Chain;
      begin
         C := Build_Shortest_Chain (100);
         pragma Unreferenced (C);
      end Bad_Build_S;

      procedure Bad_Mod is
         R : Long_Integer;
      begin
         R := Pow_Mod (2, 5, 1);
         pragma Unreferenced (R);
      end Bad_Mod;

      procedure Bad_Eval_Mod is
         R : Long_Integer;
         C : constant Chain := Build_Binary_Chain (3);
      begin
         R := Evaluate_Chain_Mod (2, 0, C);
         pragma Unreferenced (R);
      end Bad_Eval_Mod;

      procedure Bad_Naive is
         R : Long_Integer;
      begin
         R := Power_Naive (2, Max_Naive_Exp + 1);
         pragma Unreferenced (R);
      end Bad_Naive;

      procedure Bad_Chain_Count is
         C : Chain;
         N : Natural;
      begin
         C.Last := 1;
         C.Elements (0) := 1;
         C.Elements (1) := 5;
         N := Chain_Mul_Count (C);
         pragma Unreferenced (N);
      end Bad_Chain_Count;

      procedure Bad_Power_Mod_Exp is
         R : Long_Integer;
      begin
         R := Power_By_Chain_Mod (2, 0, 17);
         pragma Unreferenced (R);
      end Bad_Power_Mod_Exp;
   begin
      Check (Raised_Invalid (Bad_Shortest'Access),
             "Shortest_Chain_Length(33) raises");
      Check (Raised_Invalid (Bad_Build_S'Access),
             "Build_Shortest_Chain(100) raises");
      Check (Raised_Invalid (Bad_Mod'Access),
             "Pow_Mod modulus 1 raises");
      Check (Raised_Invalid (Bad_Eval_Mod'Access),
             "Evaluate_Chain_Mod modulus 0 raises");
      Check (Raised_Invalid (Bad_Naive'Access),
             "Power_Naive over Max raises");
      Check (Raised_Invalid (Bad_Chain_Count'Access),
             "Chain_Mul_Count invalid raises");
      Check (Raised_Invalid (Bad_Power_Mod_Exp'Access),
             "Power_By_Chain_Mod Exp=0 raises");
   end;

   ------------------------------------------------------------------
   Section ("11. Binary_Mul_Count ≥ Shortest for 1..32");
   ------------------------------------------------------------------
   declare
      Sample : constant array (Positive range <>) of Positive :=
        [1, 7, 15, 23, 27, 30, 31, 32];
   begin
      for N of Sample loop
         Check (Binary_Mul_Count (N) >= Shortest_Chain_Length (N),
                "binary ≥ shortest n=" & N'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("----------------------------------------");
   Ada.Text_IO.Put_Line
     ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Ada.Text_IO.Put_Line ("ALL PASSED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line ("SOME FAILED");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Tests;
