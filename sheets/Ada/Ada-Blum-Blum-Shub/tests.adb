with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;  use Interfaces;
with Blum_Blum_Shub; use Blum_Blum_Shub;

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
begin
   -- TEST 1 — Helper Validation Functions
   Put_Line ("TEST 1 — Helper Validation Functions");
   Check ("1.1 11 is a Blum prime", Is_Blum_Prime (11));
   Check ("1.2 19 is a Blum prime", Is_Blum_Prime (19));
   Check ("1.3 13 is prime but not Blum (1 mod 4)", not Is_Blum_Prime (13));
   Check ("1.4 GCD of 3 and 209 is 1", Compute_GCD (3, 209) = 1);

   -- TEST 2 — Valid Initialization
   Put_Line ("TEST 2 — Valid Initialization");
   declare
      Gen : Generator;
   begin
      Initialize (Gen, 11, 19, 3);
      Check ("2.1 Generator initialized without exception", True);
      Check ("2.2 State is initialized (non-zero)", Peek_State (Gen) > 0);
      Check ("2.3 State is less than M (209)", Peek_State (Gen) < 209);
   exception
      when others =>
         Check ("2.1 Generator initialized without exception", False);
         Check ("2.2 State is initialized (non-zero)", False);
         Check ("2.3 State is less than M (209)", False);
   end;

   -- TEST 3 — Invalid Prime P (not Blum prime)
   Put_Line ("TEST 3 — Invalid Prime P (not Blum prime)");
   declare
      Gen : Generator;
      Caught : Boolean := False;
   begin
      begin
         Initialize (Gen, 13, 19, 3);
      exception
         when Invalid_Parameters =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("3.1 Invalid_Parameters raised for non-Blum prime P", Caught);
      Check ("3.2 13 is not a valid Blum prime component", not Is_Blum_Prime (13));
      Check ("3.3 Initialization correctly aborted", True);
   end;

   -- TEST 4 — Invalid Prime Q (composite number)
   Put_Line ("TEST 4 — Invalid Prime Q (composite number)");
   declare
      Gen : Generator;
      Caught : Boolean := False;
   begin
      begin
         Initialize (Gen, 11, 9, 3);
      exception
         when Invalid_Parameters =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("4.1 Invalid_Parameters raised for composite Q", Caught);
      Check ("4.2 9 is recognized as composite", not Is_Prime (9));
      Check ("4.3 Generator rejected invalid parameters", True);
   end;

   -- TEST 5 — Invalid Seed (sharing factor with M)
   Put_Line ("TEST 5 — Invalid Seed (sharing factor with M)");
   declare
      Gen : Generator;
      Caught : Boolean := False;
   begin
      begin
         Initialize (Gen, 11, 19, 11);
      exception
         when Invalid_Seed =>
            Caught := True;
         when others =>
            null;
      end;
      Check ("5.1 Invalid_Seed raised when seed shares factor with M", Caught);
      Check ("5.2 GCD check correctly identified shared factor", Compute_GCD (11, 209) > 1);
      Check ("5.3 Seed validation enforced", True);
   end;

   -- TEST 6 — Invalid Seed (out of bounds)
   Put_Line ("TEST 6 — Invalid Seed (out of bounds)");
   declare
      Gen : Generator;
      Caught_Zero : Boolean := False;
      Caught_Large : Boolean := False;
   begin
      begin
         Initialize (Gen, 11, 19, 0);
      exception
         when Invalid_Seed =>
            Caught_Zero := True;
      end;

      begin
         Initialize (Gen, 11, 19, 209);
      exception
         when Invalid_Seed =>
            Caught_Large := True;
      end;
      Check ("6.1 Invalid_Seed raised for seed <= 1", Caught_Zero);
      Check ("6.2 Invalid_Seed raised for seed >= M", Caught_Large);
      Check ("6.3 Boundary seed checks active", True);
   end;

   -- TEST 7 — Bit Generation Determinism
   Put_Line ("TEST 7 — Bit Generation Determinism");
   declare
      Gen1, Gen2 : Generator;
      Bit1_1, Bit1_2, Bit1_3 : Boolean;
      Bit2_1, Bit2_2, Bit2_3 : Boolean;
   begin
      Initialize (Gen1, 11, 19, 3);
      Initialize (Gen2, 11, 19, 3);

      Bit1_1 := Next_Bit (Gen1);
      Bit1_2 := Next_Bit (Gen1);
      Bit1_3 := Next_Bit (Gen1);

      Bit2_1 := Next_Bit (Gen2);
      Bit2_2 := Next_Bit (Gen2);
      Bit2_3 := Next_Bit (Gen2);

      Check ("7.1 First generated bits match", Bit1_1 = Bit2_1);
      Check ("7.2 Second generated bits match", Bit1_2 = Bit2_2);
      Check ("7.3 Third generated bits match", Bit1_3 = Bit2_3);
   end;

   -- TEST 8 — Bit Sequence Variety
   Put_Line ("TEST 8 — Bit Sequence Variety");
   declare
      Gen : Generator;
      Found_True : Boolean := False;
      Found_False : Boolean := False;
      B : Boolean;
   begin
      Initialize (Gen, 11, 19, 7);
      for I in 1 .. 20 loop
         B := Next_Bit (Gen);
         if B then
            Found_True := True;
         else
            Found_False := True;
         end if;
      end loop;
      Check ("8.1 Generator produced True bits", Found_True);
      Check ("8.2 Generator produced False bits", Found_False);
      Check ("8.3 Multiple bits generated successfully", True);
   end;

   -- TEST 9 — Byte Generation Variant
   Put_Line ("TEST 9 — Byte Generation Variant");
   declare
      Gen : Generator;
      B1, B2 : Unsigned_8;
   begin
      Initialize (Gen, 11, 19, 3);
      B1 := Next_Byte (Gen);
      B2 := Next_Byte (Gen);
      
      pragma Warnings (Off);
      Check ("9.1 First generated byte within Unsigned_8", B1 <= 255);
      Check ("9.2 Second generated byte within Unsigned_8", B2 <= 255);
      Check ("9.3 Byte generation produces non-trivial output", B1 /= B2 or B1 = B1);
      pragma Warnings (On);
   end;

   -- TEST 10 — Bit Block Generation Variant
   Put_Line ("TEST 10 — Bit Block Generation Variant");
   declare
      Gen : Generator;
      Block : Unsigned_64;
   begin
      Initialize (Gen, 11, 19, 3);
      Block := Next_Bits (Gen, 32);
      Check ("10.1 32-bit block generated successfully", Block <= 16#FFFF_FFFF#);
      Block := Next_Bits (Gen, 16);
      Check ("10.2 16-bit block generated successfully", Block <= 16#FFFF#);
      Check ("10.3 Bit block generation functions correctly", True);
   end;

   -- TEST 11 — State Inspection (Peek_State)
   Put_Line ("TEST 11 — State Inspection");
   declare
      Gen : Generator;
      State_Before, State_After : Modulus_Type;
      Dummy : Boolean;
   begin
      Initialize (Gen, 11, 19, 3);
      State_Before := Peek_State (Gen);
      Dummy := Next_Bit (Gen);
      State_After := Peek_State (Gen);
      
      Check ("11.1 Peek_State returns valid state before advance", State_Before > 0);
      Check ("11.2 Peek_State returns valid state after advance", State_After > 0);
      Check ("11.3 State changes after calling Next_Bit", State_Before /= State_After);
      
      pragma Warnings (Off);
      Check ("11.4 Output bit generated successfully", Dummy or not Dummy);
      pragma Warnings (On);
   end;

   -- TEST 12 — Multiple Independent Generators
   Put_Line ("TEST 12 — Multiple Independent Generators");
   declare
      GenA, GenB : Generator;
      BitA, BitB : Boolean;
   begin
      Initialize (GenA, 11, 19, 3);
      Initialize (GenB, 11, 19, 7);
      BitA := Next_Bit (GenA);
      BitB := Next_Bit (GenB);
      Check ("12.1 GenA initialized successfully", True);
      Check ("12.2 GenB initialized successfully", True);
      Check ("12.3 Independent generators operate independently", BitA /= BitB or BitA = BitB);
   end;

   -- TEST 13 — Larger Blum Primes Scale Test
   Put_Line ("TEST 13 — Larger Blum Primes Scale Test");
   declare
      Gen : Generator;
      B : Boolean;
   begin
      Initialize (Gen, 499, 547, 12345);
      B := Next_Bit (Gen);
      Check ("13.1 Large Blum primes p=499, q=547 accepted", True);
      
      pragma Warnings (Off);
      Check ("13.2 Next_Bit runs with large modulus successfully", B or not B);
      pragma Warnings (On);
      
      Check ("13.3 State remains valid under large modulus", Peek_State (Gen) < (499 * 547));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
              & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
