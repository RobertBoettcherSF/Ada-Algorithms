--  Standalone test suite for Approximate_Counting (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Approximate_Counting; use Approximate_Counting;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Approximate_Counting test suite");
   Put_Line ("================================");

   ---------------------------------------------------------------------
   Section ("1. Create / Exponent / Base defaults");
   ---------------------------------------------------------------------
   declare
      C0 : constant Counter := Create;
      C5 : constant Counter := Create (Initial_Exponent => 5);
      Cb : constant Counter := Create (Initial_Exponent => 0, Base => 4.0);
   begin
      Check (Exponent (C0) = 0, "Create default exponent is 0");
      Check (Near (Base_Of (C0), 2.0), "Create default base is 2");
      Check (Approx (Estimate (C0), 0.0), "Estimate(c=0) = 0 = 2^0-1");
      Check (Approx (Power_Approximation (C0), 1.0), "Power_Approx(c=0) = 1");
      Check (Exponent (C5) = 5, "Create(5) stores exponent 5");
      Check (Approx (Estimate (C5), 31.0), "Estimate(c=5) = 2^5-1 = 31");
      Check (Approx (Power_Approximation (C5), 32.0),
             "Wiki: c=5 Approximation = 32");
      Check (Near (Base_Of (Cb), 4.0), "Create with Base=4");
      Check (Approx (Estimate (Cb), 0.0), "Base-4 c=0 estimate 0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Increment_Probability / Power helpers");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      Check (Approx (Increment_Probability (0), 1.0), "p(c=0)=1");
      Check (Approx (Increment_Probability (1), 0.5), "p(c=1)=1/2");
      Check (Approx (Increment_Probability (2), 0.25), "p(c=2)=1/4");
      Check (Approx (Increment_Probability (3), 0.125), "p(c=3)=1/8");
      Check (Approx (Increment_Probability (4), 0.0625), "p(c=4)=1/16");
      Check (Approx (Increment_Probability (5), 1.0 / 32.0), "p(c=5)=1/32");
      Check (Approx (Power (2.0, 0), 1.0), "Power(2,0)=1");
      Check (Approx (Power (2.0, 5), 32.0), "Power(2,5)=32");
      Check (Approx (Power (2.0, 10), 1024.0), "Power(2,10)=1024");
      Check (Approx (Increment_Probability (2, 4.0), 1.0 / 16.0),
             "p(c=2,b=4)=4^{-2}=1/16");
      Check (Near (1.0, 1.0), "Near accepts equal");
      Check (not Near (1.0, 2.0), "Near rejects far");
      begin
         declare
            Unused : Real := Power (-1.0, 3);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Power(negative) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("3. Forced increments via injected Uniform draws");
   ---------------------------------------------------------------------
   declare
      C : Counter := Create;
   begin
      --  U = 0.0 always < p for any finite c with p > 0.
      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 1, "Forced: c=0 -> 1 with U=0");
      Check (Approx (Estimate (C), 1.0), "Forced: Estimate after first = 1");

      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 2, "Forced: c=1 -> 2 with U=0");
      Check (Approx (Estimate (C), 3.0), "Forced: Estimate = 3");

      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 3, "Forced: c=2 -> 3 with U=0");
      Check (Approx (Estimate (C), 7.0), "Forced: Estimate = 7");

      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 4, "Forced: c=3 -> 4 with U=0");
      Check (Approx (Estimate (C), 15.0), "Forced: Estimate = 15");

      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 5, "Forced: c=4 -> 5 with U=0");
      Check (Approx (Estimate (C), 31.0), "Forced: Estimate = 31");
      Check (Approx (Power_Approximation (C), 32.0),
             "Forced: Power_Approx = 32 after five forced bumps");
   end;

   ---------------------------------------------------------------------
   Section ("4. Rejected increments (U >= p)");
   ---------------------------------------------------------------------
   declare
      C : Counter := Create (Initial_Exponent => 3);  -- p = 1/8 = 0.125
   begin
      Increment_With_Probability (C, 0.125);  -- U = p, not < p
      Check (Exponent (C) = 3, "U=p does not increment");
      Increment_With_Probability (C, 0.5);
      Check (Exponent (C) = 3, "U=0.5 > p leaves c=3");
      Increment_With_Probability (C, 0.999);
      Check (Exponent (C) = 3, "U=0.999 leaves c=3");
      Increment_With_Probability (C, 0.124);
      Check (Exponent (C) = 4, "U=0.124 < 0.125 increments to 4");
   end;

   ---------------------------------------------------------------------
   Section ("5. Wikipedia Base-2 table (Approximation / Estimate / E)");
   ---------------------------------------------------------------------
   declare
      --  Wiki: Stored c | Approximation 2^c | Expectation ~ 2^{c+1}-2
      type Row is record
         C    : Exponent_Value;
         Pow2 : Real;
         Expn : Real;  -- wiki expectation column
      end record;
      Table : constant array (Positive range <>) of Row :=
        [(0, 1.0, 0.0),
         (1, 2.0, 2.0),
         (2, 4.0, 6.0),
         (3, 8.0, 14.0),
         (4, 16.0, 30.0),
         (5, 32.0, 62.0)];
   begin
      for R of Table loop
         declare
            Ctr : constant Counter := Create (Initial_Exponent => R.C);
         begin
            Check (Approx (Power_Approximation (Ctr), R.Pow2),
                   "Wiki approx 2^c for c=" & R.C'Image);
            Check (Approx (Estimate (Ctr), R.Pow2 - 1.0),
                   "Unbiased 2^c-1 for c=" & R.C'Image);
            Check (Approx (Expectation_Given_Exponent (Ctr), R.Expn),
                   "Wiki expectation for c=" & R.C'Image);
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("6. Increment with seeded RNG / Increment_Many");
   ---------------------------------------------------------------------
   declare
      C1, C2 : Counter := Create;
      S1, S2 : RNG_State;
   begin
      Seed_RNG (S1, 42);
      Seed_RNG (S2, 42);
      for I in 1 .. 20 loop
         Increment (C1, S1);
         Increment (C2, S2);
      end loop;
      Check (Exponent (C1) = Exponent (C2),
             "Same seed => identical exponents after 20 increments");
      Check (Approx (Estimate (C1), Estimate (C2)),
             "Same seed => identical estimates");

      --  c=0 always increments on first draw
      declare
         C : Counter := Create;
         S : RNG_State;
      begin
         Seed_RNG (S, 1);
         Increment (C, S);
         Check (Exponent (C) = 1, "First Increment from c=0 always bumps");
      end;

      --  Increment_Many equivalence
      declare
         Ca, Cb : Counter := Create;
         Sa, Sb : RNG_State;
      begin
         Seed_RNG (Sa, 99);
         Seed_RNG (Sb, 99);
         Increment_Many (Ca, 50, Sa);
         for I in 1 .. 50 loop
            Increment (Cb, Sb);
         end loop;
         Check (Exponent (Ca) = Exponent (Cb),
                "Increment_Many(50) matches 50x Increment");
         Check (Approx (Estimate (Ca), Estimate (Cb)),
                "Increment_Many estimates match");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Order-of-magnitude near n (fixed seed, many increments)");
   ---------------------------------------------------------------------
   declare
      --  For unbiased estimator E[2^c - 1] = n, after n increments estimate
      --  should be order-of-magnitude near n (within a generous factor).
      procedure Check_Near_N (N : Natural; Seed : Natural; Label : String) is
         C : Counter := Create;
         S : RNG_State;
         Est : Real;
         Ratio : Real;
      begin
         Seed_RNG (S, Seed);
         Increment_Many (C, N, S);
         Est := Estimate (C);
         Check (Est >= 0.0, Label & ": estimate non-negative");
         --  Never claim more precision than the counter can hold: estimate
         --  after n steps cannot exceed the forced-success path 2^n - 1,
         --  and for large n stays well below absurd multiples of n.
         if N > 0 then
            Check (Est <= Real (N) * 64.0 + 1.0,
                   Label & ": estimate not wildly above n");
            --  Order-of-magnitude: Est within [n/64, 64*n] typically;
            --  allow missing the lower bound only if Est is still small
            --  relative to a forced chain (rare under-estimate).
            if Est > 0.0 then
               Ratio := Real (N) / Est;
               Check (Ratio < 256.0 and then Ratio > 1.0 / 256.0,
                      Label & ": Est order-of-magnitude near n");
            else
               Check (False, Label & ": Est should be > 0 for n>0");
            end if;
         end if;
         --  Exponent never exceeds log2(n)+slack for typical runs
         Check (Exponent (C) <= Max_Exponent, Label & ": c <= Max_Exponent");
      end Check_Near_N;
   begin
      Check_Near_N (100, 12345, "n=100");
      Check_Near_N (1_000, 7, "n=1000");
      Check_Near_N (10_000, 2026, "n=10000");

      --  Multiple seeds for n=1000: all estimates in a sane band
      for Seed in 1 .. 3 loop
         declare
            C : Counter := Create;
            S : RNG_State;
            Est : Real;
         begin
            Seed_RNG (S, Seed * 17);
            Increment_Many (C, 1_000, S);
            Est := Estimate (C);
            Check (Est > 10.0 and then Est < 50_000.0,
                   "n=1000 seed" & Seed'Image & " Est in (10,50000)");
         end;
      end loop;
   end;

   ---------------------------------------------------------------------
   Section ("8. Never exceeds impossible forced path");
   ---------------------------------------------------------------------
   declare
      C : Counter := Create;
      S : RNG_State;
      Forced : Counter := Create;
      Ok_Bound, Ok_Forced, Ok_Est : Boolean := True;
   begin
      Seed_RNG (S, 314159);
      --  After k random increments, c cannot exceed k (each step +0 or +1).
      for K in 1 .. 30 loop
         Increment (C, S);
         Increment_With_Probability (Forced, 0.0);
         if Exponent (C) > K then
            Ok_Bound := False;
         end if;
         if Exponent (C) > Exponent (Forced) then
            Ok_Forced := False;
         end if;
         if Estimate (C) > Estimate (Forced) + 1.0E-6 then
            Ok_Est := False;
         end if;
      end loop;
      Check (Ok_Bound, "After each of 30 steps, c <= k");
      Check (Ok_Forced, "Random c always <= forced-success path");
      Check (Ok_Est, "Random estimate always <= forced estimate");
      Check (Exponent (C) <= 30, "Final random exponent <= 30");
      Check (Exponent (Forced) = 30, "Forced path reaches c=30 after 30 bumps");
   end;

   ---------------------------------------------------------------------
   Section ("9. Capacity / invalid ops");
   ---------------------------------------------------------------------
   declare
      Raised_Cap : Boolean := False;
      Raised_Pow : Boolean := False;
      C : Counter := Create (Initial_Exponent => Max_Exponent);
   begin
      begin
         Increment_With_Probability (C, 0.0);
      exception
         when Capacity_Exceeded =>
            Raised_Cap := True;
         when others =>
            null;
      end;
      Check (Raised_Cap, "Increment at Max_Exponent raises Capacity_Exceeded");
      Check (Exponent (C) = Max_Exponent, "Exponent unchanged after capacity fail");

      begin
         declare
            Unused : Real := Power (0.0, 5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Pow := True;
         when others =>
            null;
      end;
      Check (Raised_Pow, "Power(0,5) raises Invalid_Argument");

      --  Increment_Many with N=0 is a no-op
      declare
         C0 : Counter := Create (Initial_Exponent => 3);
         S  : RNG_State;
      begin
         Seed_RNG (S, 1);
         Increment_Many (C0, 0, S);
         Check (Exponent (C0) = 3, "Increment_Many(0) is no-op");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. General base b > 1");
   ---------------------------------------------------------------------
   declare
      C : Counter := Create (Initial_Exponent => 0, Base => 4.0);
   begin
      Check (Approx (Estimate (C), 0.0), "b=4 c=0: estimate 0");
      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 1, "b=4 forced bump to 1");
      --  n̂ = (4^1 - 1)/(4-1) = 1
      Check (Approx (Estimate (C), 1.0), "b=4 c=1: estimate 1");
      Increment_With_Probability (C, 0.0);
      Check (Exponent (C) = 2, "b=4 forced bump to 2");
      --  n̂ = (16-1)/3 = 5
      Check (Approx (Estimate (C), 5.0), "b=4 c=2: estimate 5");
      Check (Approx (Power_Approximation (C), 16.0), "b=4 c=2: power 16");
      Check (Approx (Increment_Probability (2, 4.0), 1.0 / 16.0),
             "b=4 c=2: p=1/16");
      --  Reject path
      Increment_With_Probability (C, 0.1);  -- 0.1 > 1/16=0.0625
      Check (Exponent (C) = 2, "b=4 U>p leaves c=2");
      Increment_With_Probability (C, 0.01);
      Check (Exponent (C) = 3, "b=4 U<p bumps to 3");
      Check (Approx (Estimate (C), (64.0 - 1.0) / 3.0),
             "b=4 c=3: estimate (64-1)/3");
   end;

   ---------------------------------------------------------------------
   Section ("11. RNG unit interval / reproducibility");
   ---------------------------------------------------------------------
   declare
      S1, S2 : RNG_State;
      U1, U2 : Unit_Interval;
      All_In : Boolean := True;
      Same   : Boolean := True;
   begin
      Seed_RNG (S1, 0);  -- seed 0 maps to state 1
      Seed_RNG (S2, 0);
      for I in 1 .. 100 loop
         U1 := Next_Unit (S1);
         U2 := Next_Unit (S2);
         if U1 /= U2 or else U1 >= 1.0 or else U1 < 0.0 then
            All_In := False;
         end if;
      end loop;
      Check (All_In, "Next_Unit reproducible and in [0,1)");

      Seed_RNG (S1, 123);
      Seed_RNG (S2, 456);
      for I in 1 .. 5 loop
         if Next_Unit (S1) /= Next_Unit (S2) then
            Same := False;
         end if;
      end loop;
      Check (not Same, "Seeds 123 vs 456 produce different sequences");
   end;

   ---------------------------------------------------------------------
   Section ("12. Estimate formula table for forced chain");
   ---------------------------------------------------------------------
   declare
      C : Counter := Create;
      Expected_Est : constant array (0 .. 5) of Real :=
        [0.0, 1.0, 3.0, 7.0, 15.0, 31.0];
   begin
      Check (Approx (Estimate (C), Expected_Est (0)), "chain est c=0");
      for K in 1 .. 5 loop
         Increment_With_Probability (C, 0.0);
         Check (Exponent (C) = K, "chain exponent =" & K'Image);
         Check (Approx (Estimate (C), Expected_Est (K)),
                "chain Estimate = 2^c-1 at c=" & K'Image);
         Check (Approx (Power_Approximation (C), Expected_Est (K) + 1.0),
                "chain Power_Approx = 2^c at c=" & K'Image);
      end loop;
   end;

   New_Line;
   Put_Line ("================================");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("================================");

   pragma Assert (Fail_Count = 0, "Approximate_Counting tests failed");
end Tests;
