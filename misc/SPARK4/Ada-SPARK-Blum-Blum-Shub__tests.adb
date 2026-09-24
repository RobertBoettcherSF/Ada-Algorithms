--  Standalone test suite for Blum_Blum_Shub (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Blum_Blum_Shub; use Blum_Blum_Shub;

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

   --  Non-static views (avoid -gnatwa constant-condition warnings).
   function Nat (X : Natural) return Natural is (X);
   function V (X : Long_Long_Integer) return Value is (Value (X));
   function B (X : Boolean) return Boolean is (X);

   function Next_Bit_Val (G : in out Generator) return Boolean is
      R : Boolean;
   begin
      Next_Bit (G, R);
      return R;
   end Next_Bit_Val;

   function Next_Byte_Val (G : in out Generator) return Value is
      R : Value;
   begin
      Next_Byte (G, R);
      return R;
   end Next_Byte_Val;

   function Next_Bits_Val (G : in out Generator; Count : Bit_Count) return Value
   is
      R : Value;
   begin
      Next_Bits (G, Count, R);
      return R;
   end Next_Bits_Val;

   type Bool_Array is array (Positive range <>) of Boolean;

   function Bits_Match
     (P, Q, Seed : Value; Expected : Bool_Array) return Boolean
   is
      G : Generator := Create (P, Q, Seed);
      Bit : Boolean;
   begin
      for I in Expected'Range loop
         Bit := Next_Bit_Val (G);
         if Bit /= Expected (I) then
            return False;
         end if;
      end loop;
      return True;
   end Bits_Match;

begin
   -------------------------------------------------------------------------
   Section ("1. Helper validation — primes / Blum / GCD");
   -------------------------------------------------------------------------
   Check (Is_Prime (V (11)), "1.1 11 is prime");
   Check (Is_Prime (V (19)), "1.2 19 is prime");
   Check (not Is_Prime (V (9)), "1.3 9 is composite");
   Check (not Is_Prime (V (1)), "1.4 1 is not prime");
   Check (not Is_Prime (V (0)), "1.5 0 is not prime");
   Check (Is_Prime (V (2)), "1.6 2 is prime");
   Check (Is_Prime (V (3)), "1.7 3 is prime");
   Check (Is_Blum_Prime (V (11)), "1.8 11 is a Blum prime");
   Check (Is_Blum_Prime (V (19)), "1.9 19 is a Blum prime");
   Check (not Is_Blum_Prime (V (13)), "1.10 13 is prime but not Blum (1 mod 4)");
   Check (not Is_Blum_Prime (V (9)), "1.11 9 is not a Blum prime");
   Check (Is_Blum_Prime (Blum_7), "1.12 Blum_7 constant");
   Check (Is_Blum_Prime (Blum_499), "1.13 Blum_499 constant");
   Check (Is_Blum_Prime (Blum_547), "1.14 Blum_547 constant");
   Check (Gcd (V (3), V (209)) = 1, "1.15 GCD(3, 209) = 1");
   Check (Gcd (V (11), V (209)) = 11, "1.16 GCD(11, 209) = 11");
   Check (Are_Coprime (V (3), V (209)), "1.17 3 and 209 are coprime");
   Check (not Are_Coprime (V (11), V (209)), "1.18 11 and 209 are not coprime");

   -------------------------------------------------------------------------
   Section ("2. Validation helpers (contracts replace exceptions)");
   -------------------------------------------------------------------------
   Check (Is_Valid_Blum_Pair (V (11), V (19)), "2.1 (11,19) is a valid Blum pair");
   Check (not Is_Valid_Blum_Pair (V (13), V (19)), "2.2 (13,19) rejected — 13 not Blum");
   Check (not Is_Valid_Blum_Pair (V (11), V (9)), "2.3 (11,9) rejected — 9 composite");
   Check (not Is_Valid_Blum_Pair (V (11), V (11)), "2.4 (11,11) rejected — not distinct");
   Check (Is_Valid_Seed (V (3), V (209)), "2.5 seed 3 valid for M=209");
   Check (not Is_Valid_Seed (V (11), V (209)), "2.6 seed 11 shares factor with M");
   Check (not Is_Valid_Seed (V (0), V (209)), "2.7 seed 0 rejected");
   Check (not Is_Valid_Seed (V (1), V (209)), "2.8 seed 1 rejected");
   Check (not Is_Valid_Seed (V (209), V (209)), "2.9 seed >= M rejected");
   Check (Is_Valid_Modulus (V (209)), "2.10 M=209 in Modulus_Type");
   Check (not Is_Valid_Modulus (V (1)), "2.11 M=1 not a valid modulus");
   Check (not Is_Valid_Modulus (Max_Modulus + 1), "2.12 M > Max_Modulus rejected");

   -------------------------------------------------------------------------
   Section ("3. Educational Blum-prime table");
   -------------------------------------------------------------------------
   declare
      All_Blum : Boolean := True;
   begin
      for I in Small_Blum_Primes'Range loop
         if not Is_Blum_Prime (Small_Blum_Primes (I)) then
            All_Blum := False;
         end if;
         if Small_Blum_Primes (I) > Max_Prime then
            All_Blum := False;
         end if;
      end loop;
      Check (All_Blum, "3.1 every Small_Blum_Primes entry is Blum and ≤ Max_Prime");
      Check (Nat (Small_Blum_Primes'Length) >= 20, "3.2 table has educational coverage");
   end;

   -------------------------------------------------------------------------
   Section ("4. Valid Create / Initialize");
   -------------------------------------------------------------------------
   declare
      Gen  : constant Generator := Create (V (11), V (19), V (3));
      Gen2 : Generator;
   begin
      Check (Is_Initialised (Gen), "4.1 Create initialises generator");
      Check (Peek_State (Gen) > 0, "4.2 initial state non-zero");
      Check (Peek_State (Gen) < 209, "4.3 initial state < M");
      Check (Peek_State (Gen) = 9, "4.4 initial state = seed² mod M = 9");
      Check (Get_P (Gen) = 11, "4.5 Get_P");
      Check (Get_Q (Gen) = 19, "4.6 Get_Q");
      Check (Get_M (Gen) = 209, "4.7 Get_M");
      Check (Get_Seed (Gen) = 3, "4.8 Get_Seed");
      Initialize (Gen2, V (11), V (19), V (3));
      Check (Is_Initialised (Gen2), "4.9 Initialize initialises generator");
      Check (Peek_State (Gen2) = Peek_State (Gen), "4.10 Initialize matches Create state");
   end;

   -------------------------------------------------------------------------
   Section ("5. Known bit sequence p=11,q=19,seed=3");
   -------------------------------------------------------------------------
   --  Init state = 9; successive squares mod 209 yield LSBs:
   --  81,82,36,42,92,104,157,196 → bits 1,0,0,0,0,0,1,0
   Check
     (Bits_Match
        (V (11), V (19), V (3),
         [True, False, False, False, False, False, True, False,
          True, True, False, True, True, False, False, False]),
      "5.1 first 16 bits match hand-computed sequence");

   -------------------------------------------------------------------------
   Section ("6. Determinism");
   -------------------------------------------------------------------------
   declare
      Gen1 : Generator := Create (V (11), V (19), V (3));
      Gen2 : Generator := Create (V (11), V (19), V (3));
      Match : Boolean := True;
      B1, B2 : Boolean;
   begin
      for I in 1 .. 32 loop
         B1 := Next_Bit_Val (Gen1);
         B2 := Next_Bit_Val (Gen2);
         if B1 /= B2 then
            Match := False;
         end if;
      end loop;
      Check (Match, "6.1 identical Create seeds produce identical bits");
   end;

   declare
      Gen : Generator := Create (V (11), V (19), V (7));
      First : Bool_Array (1 .. 16);
      Match : Boolean := True;
   begin
      for I in First'Range loop
         First (I) := Next_Bit_Val (Gen);
      end loop;
      Reset (Gen, V (7));
      for I in First'Range loop
         if Next_Bit_Val (Gen) /= First (I) then
            Match := False;
         end if;
      end loop;
      Check (Match, "6.2 Reset replays the same bit sequence");
   end;

   -------------------------------------------------------------------------
   Section ("7. Bit sequence variety");
   -------------------------------------------------------------------------
   declare
      Gen : Generator := Create (V (11), V (19), V (7));
      Found_True  : Boolean := False;
      Found_False : Boolean := False;
      Bit : Boolean;
   begin
      for I in 1 .. 20 loop
         Bit := Next_Bit_Val (Gen);
         if Bit then
            Found_True := True;
         else
            Found_False := True;
         end if;
      end loop;
      Check (Found_True, "7.1 produced True bits");
      Check (Found_False, "7.2 produced False bits");
   end;

   -------------------------------------------------------------------------
   Section ("8. Next_Byte / Next_Bits");
   -------------------------------------------------------------------------
   declare
      Gen : Generator := Create (V (11), V (19), V (3));
      Gen_Bits : Generator := Create (V (11), V (19), V (3));
      B1, B2 : Value;
      Block32, Block16 : Value;
      Acc : Value := 0;
      Bit : Boolean;
   begin
      B1 := Next_Byte_Val (Gen);
      B2 := Next_Byte_Val (Gen);
      Check (B1 <= 255, "8.1 first byte ≤ 255");
      Check (B2 <= 255, "8.2 second byte ≤ 255");
      --  Rebuild first byte from Next_Bit (MSB-first)
      for I in 1 .. 8 loop
         Bit := Next_Bit_Val (Gen_Bits);
         Acc := Acc * 2;
         if Bit then
            Acc := Acc + 1;
         end if;
      end loop;
      Check (Acc = B1, "8.3 Next_Byte matches eight Next_Bit packs");

      declare
         Gen3 : Generator := Create (V (11), V (19), V (3));
      begin
         Block32 := Next_Bits_Val (Gen3, 32);
         Check (Block32 <= 16#FFFF_FFFF#, "8.4 32-bit block within 32 bits");
         Block16 := Next_Bits_Val (Gen3, 16);
         Check (Block16 <= 16#FFFF#, "8.5 16-bit block within 16 bits");
      end;
   end;

   -------------------------------------------------------------------------
   Section ("9. Peek_State advances only on Next");
   -------------------------------------------------------------------------
   declare
      Gen : Generator := Create (V (11), V (19), V (3));
      Before, After, Peek2 : Value;
      Dummy : Boolean;
   begin
      Before := Peek_State (Gen);
      Peek2  := Peek_State (Gen);
      Check (Before = Peek2, "9.1 Peek_State is non-destructive");
      Dummy := Next_Bit_Val (Gen);
      After := Peek_State (Gen);
      Check (Before /= After, "9.2 state changes after Next_Bit");
      Check (After < Get_M (Gen), "9.3 state remains < M");
      Check (B (Dummy) = B (Dummy), "9.4 Next_Bit completed");
   end;

   -------------------------------------------------------------------------
   Section ("10. Independent generators");
   -------------------------------------------------------------------------
   declare
      GenA : Generator := Create (V (11), V (19), V (3));
      GenB : Generator := Create (V (11), V (19), V (7));
      BitA : constant Boolean := Next_Bit_Val (GenA);
      BitB : constant Boolean := Next_Bit_Val (GenB);
   begin
      Check (Is_Initialised (GenA) and then Is_Initialised (GenB),
             "10.1 both generators initialised");
      Check (Get_Seed (GenA) /= Get_Seed (GenB), "10.2 distinct seeds");
      Check (B (BitA) = B (BitA), "10.3 GenA produces a bit");
      Check (B (BitB) = B (BitB), "10.4 GenB produces a bit");
   end;

   -------------------------------------------------------------------------
   Section ("11. Larger Blum primes (499, 547)");
   -------------------------------------------------------------------------
   declare
      P : constant Value := Blum_499;
      Q : constant Value := Blum_547;
      M : constant Value := P * Q;
      Gen : Generator := Create (P, Q, V (12_345));
      Bit : Boolean;
   begin
      Check (Is_Valid_Blum_Pair (P, Q), "11.1 (499,547) valid Blum pair");
      Check (M = V (272_953), "11.2 M = 272953");
      Check (Is_Initialised (Gen), "11.3 Create with large primes");
      Bit := Next_Bit_Val (Gen);
      Check (Peek_State (Gen) < M, "11.4 state < M after Next_Bit");
      Check (B (Bit) = B (Bit), "11.5 Next_Bit runs under large modulus");
   end;

   -------------------------------------------------------------------------
   Section ("12. Mul_Mod / Square_Mod");
   -------------------------------------------------------------------------
   Check (Mul_Mod (V (10), V (20), 209) = 200, "12.1 Mul_Mod 10*20 mod 209");
   Check (Mul_Mod (V (81), V (81), 209) = 82, "12.2 Mul_Mod 81² mod 209 = 82");
   Check (Square_Mod (V (81), 209) = 82, "12.3 Square_Mod 81 mod 209");
   Check (Square_Mod (V (3), 209) = 9, "12.4 Square_Mod 3 mod 209");
   Check (Mul_Mod (Max_Modulus - 1, Max_Modulus - 1, Max_Modulus) =
            (Max_Modulus - 1) * (Max_Modulus - 1) rem Max_Modulus,
          "12.5 Mul_Mod near Max_Modulus");

   -------------------------------------------------------------------------
   Section ("13. Alternate small pair (7, 11)");
   -------------------------------------------------------------------------
   declare
      Gen : constant Generator := Create (Blum_7, Blum_11, V (3));
   begin
      Check (Get_M (Gen) = 77, "13.1 M = 7*11 = 77");
      Check (Peek_State (Gen) = 9, "13.2 seed 3 → state 9");
      Check (Is_Valid_Blum_Pair (Blum_23, Blum_43), "13.3 (23,43) valid");
      Check (Is_Valid_Blum_Pair (Blum_103, Blum_107), "13.4 (103,107) valid");
   end;

   New_Line;
   Put_Line
     ("=== "
      & Natural'Image (Pass_Count)
      & " passed,"
      & Natural'Image (Fail_Count)
      & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
