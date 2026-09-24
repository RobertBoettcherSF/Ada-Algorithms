--  Standalone test suite for Mersenne_Twister (SPARK port, MT19937).
--  Preconditions replace exceptions; only valid call paths are exercised.
--  Known-answer values: OEIS A221557 / C++ std::mt19937 default seed 5489.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Interfaces; use Interfaces;
with Mersenne_Twister;
use Mersenne_Twister;

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
   function U32 (X : Unsigned_32) return Unsigned_32 is (X);

   function Next_Val (G : in out Generator) return Unsigned_32 is
      R : Unsigned_32;
   begin
      Next (G, R);
      return R;
   end Next_Val;

   type U32_Array is array (Positive range <>) of Unsigned_32;

   --  First 20 outputs of MT19937 with seed 5489 (OEIS A221557).
   KAT_5489 : constant U32_Array :=
     [3_499_211_612, 581_869_302, 3_890_346_734, 3_586_334_585,
      545_404_204, 4_161_255_391, 3_922_919_429, 949_333_985,
      2_715_962_298, 1_323_567_403, 418_932_835, 2_350_294_565,
      1_196_140_740, 809_094_426, 2_348_838_239, 4_264_392_720,
      4_112_460_519, 4_279_768_804, 4_144_164_697, 4_156_218_106];

   G, G2 : Generator;
   X, Y, Z : Unsigned_32;
   B : Boolean;
   Idx : Index_Type;

begin
   Put_Line ("Mersenne_Twister SPARK V&V Test Suite (MT19937)");
   Put_Line ("------------------------------------------------------------");

   -----------------------------------------------------------------
   Section ("Known-answer sequence (seed 5489)");
   -----------------------------------------------------------------
   G := Create (U32 (5489));
   B := True;
   for I in KAT_5489'Range loop
      X := Next_Val (G);
      if X /= KAT_5489 (I) then
         B := False;
         Put_Line ("    mismatch at" & I'Image
                   & " got" & X'Image
                   & " want" & KAT_5489 (I)'Image);
      end if;
   end loop;
   Check (B, "first 20 outputs match OEIS A221557 / std::mt19937");

   Init (G, Default_Seed);
   Check (Next_Val (G) = KAT_5489 (1), "Init(Default_Seed) first word");
   Check (U32 (Default_Seed) = U32 (5489), "Default_Seed is 5489");

   -----------------------------------------------------------------
   Section ("Reproducibility and seed independence");
   -----------------------------------------------------------------
   G := Create (U32 (12_345));
   G2 := Create (U32 (12_345));
   Check (Next_Val (G) = Next_Val (G2), "identical seeds: 1st match");
   for I in 2 .. 100 loop
      X := Next_Val (G);
      Y := Next_Val (G2);
   end loop;
   Check (Next_Val (G) = Next_Val (G2), "identical seeds: 101st match");

   G := Create (U32 (9999));
   G2 := Create (U32 (10_000));
   Check (Next_Val (G) /= Next_Val (G2), "different seeds diverge");

   -----------------------------------------------------------------
   Section ("Create / Init / Reset contracts");
   -----------------------------------------------------------------
   G := Create (U32 (42));
   Check (Is_Initialised (G), "Create initialises");
   Check (Get_Index (G) = N, "Create sets Index = N (need Twist)");
   Check (Get_Seed (G) = 42, "Create stores seed");
   Check (Get_MT (G, 0) = 42, "Create MT(0) = seed");

   Init (G2, U32 (99));
   Check (Is_Initialised (G2)
            and then Get_Index (G2) = N
            and then Get_Seed (G2) = 99
            and then Get_MT (G2, 0) = 99,
          "Init mirrors Create");

   X := Next_Val (G);
   Y := Next_Val (G);
   Z := Next_Val (G);
   Reset (G, U32 (42));
   Check (Get_Index (G) = N and then Get_Seed (G) = 42
            and then Get_MT (G, 0) = 42,
          "Reset restores Index/Seed/MT(0)");
   Check (Next_Val (G) = X and then Next_Val (G) = Y
            and then Next_Val (G) = Z,
          "Reset replay of first three outputs");

   -----------------------------------------------------------------
   Section ("Twist boundary (exhaust N words)");
   -----------------------------------------------------------------
   G := Create (U32 (1));
   for I in 1 .. N loop
      X := Next_Val (G);
   end loop;
   Idx := Get_Index (G);
   Check (Idx = N, "after N extracts Index = N");
   X := Next_Val (G);
   Check (Get_Index (G) = 1, "extract N+1 triggers Twist, Index = 1");

   --  Internal state mutates across Twist
   G := Create (U32 (777));
   declare
      Initial_Element : constant Unsigned_32 := Get_MT (G, 0);
   begin
      for I in 1 .. N + 1 loop
         X := Next_Val (G);
      end loop;
      Check (Get_MT (G, 0) /= Initial_Element,
             "Twist mutates MT(0)");
   end;

   -----------------------------------------------------------------
   Section ("State isolation");
   -----------------------------------------------------------------
   G := Create (U32 (42));
   G2 := Create (U32 (42));
   X := Next_Val (G);
   Check (Next_Val (G2) = X, "advancing G does not advance G2");
   Y := Next_Val (G);
   Check (Get_Index (G) = 2, "G advanced to Index 2");

   -----------------------------------------------------------------
   Section ("Zero seed edge case");
   -----------------------------------------------------------------
   G := Create (U32 (0));
   Check (Get_MT (G, 0) = 0, "zero seed stored in MT(0)");
   --  Init fill must leave a non-trivial state (not all zeros forever)
   B := False;
   for I in 1 .. Nat (10) loop
      if Get_MT (G, MT_Index (I)) /= 0 then
         B := True;
      end if;
   end loop;
   Check (B, "zero seed fill is non-trivial");
   X := Next_Val (G);
   --  First tempered output with seed 0 is non-zero for MT19937
   Check (X /= 0, "seed 0 first output nonzero");

   -----------------------------------------------------------------
   Section ("Temper helper");
   -----------------------------------------------------------------
   Check (Temper (U32 (0)) = 0, "Temper(0) = 0");
   Check (Temper (U32 (16#DEADBEEF#)) /= U32 (16#DEADBEEF#)
            or else Temper (U32 (16#CAFEBABE#)) /= U32 (16#CAFEBABE#),
          "Temper changes typical inputs");
   --  Round-trip smoke: tempering of a known state word from KAT path
   G := Create (Default_Seed);
   --  Force Twist via first Next, then compare Temper(MT(0)) with result
   --  After Create Index=N; Next twists then returns Temper(MT(0)).
   declare
      Mt0_After_Twist : Unsigned_32;
      Out0            : Unsigned_32;
   begin
      --  Peek is after Twist: call Next once and reconstruct
      Out0 := Next_Val (G);
      --  Index is now 1; MT(0) is the twisted word that was tempered
      Mt0_After_Twist := Get_MT (G, 0);
      Check (Temper (Mt0_After_Twist) = Out0,
             "Next output = Temper(MT(Index)) after Twist");
   end;

   -----------------------------------------------------------------
   Section ("Index progression");
   -----------------------------------------------------------------
   G := Create (U32 (5));
   Check (Get_Index (G) = N, "pre-Next Index = N");
   X := Next_Val (G);
   Check (Get_Index (G) = 1, "after 1st Next Index = 1");
   X := Next_Val (G);
   Check (Get_Index (G) = 2, "after 2nd Next Index = 2");
   for I in 3 .. N loop
      X := Next_Val (G);
   end loop;
   Check (Get_Index (G) = N, "after N Nexts Index = N again");

   -----------------------------------------------------------------
   Section ("Constants");
   -----------------------------------------------------------------
   declare
      Nn : constant Natural := N;
      Mm : constant Natural := M;
      A  : constant Unsigned_32 := Matrix_A;
      Up : constant Unsigned_32 := Upper_Mask;
      Lo : constant Unsigned_32 := Lower_Mask;
      Tb : constant Unsigned_32 := Temper_B;
      Tc : constant Unsigned_32 := Temper_C;
      Ff : constant Unsigned_32 := Init_F;
   begin
      Check (Nn = Nat (624), "N = 624");
      Check (Mm = Nat (397), "M = 397");
      Check (A = U32 (16#9908B0DF#), "Matrix_A");
      Check (Up = U32 (16#80000000#), "Upper_Mask");
      Check (Lo = U32 (16#7FFFFFFF#), "Lower_Mask");
      Check (Tb = U32 (16#9D2C5680#), "Temper_B");
      Check (Tc = U32 (16#EFC60000#), "Temper_C");
      Check (Ff = U32 (1_812_433_253), "Init_F");
   end;

   -----------------------------------------------------------------
   -- Summary
   -----------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("========================================");
   if Fail_Count > 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
