--  Standalone test suite for Acorn_Generator (SPARK port).
--  Preconditions replace exceptions; only valid call paths are exercised.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Acorn_Generator;
use Acorn_Generator;

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

   type Value_Array is array (Natural range <>) of Value;

   function Zero_Seeds return State_Array is
      S : constant State_Array := [others => 0];
   begin
      return S;
   end Zero_Seeds;

   function Seeds_Of (Values : Value_Array) return State_Array is
      S : State_Array := [others => 0];
   begin
      for I in Values'Range loop
         S (I - Values'First) := Values (I);
      end loop;
      return S;
   end Seeds_Of;

   function Next_Val (G : in out Generator) return Value is
      R : Value;
   begin
      Next (G, R);
      return R;
   end Next_Val;

   G, G2      : Generator;
   X, Y, Z, M : Value;
   B          : Boolean;
   Discard    : Value;
   Buf        : State_Array;
   pragma Unreferenced (Discard);

begin
   -----------------------------------------------------------------
   Section ("1. Validation helpers");
   -----------------------------------------------------------------
   Check (Is_Valid_Modulus (V (0)) = False, "Is_Valid_Modulus 0");
   Check (Is_Valid_Modulus (V (1)) = False, "Is_Valid_Modulus 1");
   Check (Is_Valid_Modulus (V (2)), "Is_Valid_Modulus 2");
   Check (Is_Valid_Modulus (Default_Modulus), "Is_Valid_Modulus Default");
   Check (Is_Valid_Order (Nat (1)), "Is_Valid_Order 1");
   Check (Is_Valid_Order (Nat (64)), "Is_Valid_Order 64");
   Check (Is_Valid_Order (Nat (65)) = False, "Is_Valid_Order 65");
   Check (Seeds_In_Range (2, 10, Seeds_Of ([V (1), V (2), V (3)])),
          "Seeds_In_Range ok");
   Check (not Seeds_In_Range (2, 10, Seeds_Of ([V (1), V (10), V (3)])),
          "Seeds_In_Range seed = M rejected");

   -----------------------------------------------------------------
   Section ("2. Tiny order-1 deterministic (Y0=1, Y1=0, M=16)");
   -----------------------------------------------------------------
   G := Create (1, 16, Seeds_Of ([V (1), V (0)]));
   Check (Is_Initialised (G), "order-1 initialised");
   Check (Order_Of (G) = 1, "order-1 Order_Of");
   Check (Modulus_Of (G) = 16, "order-1 Modulus_Of");
   Check (Get_Y (G, 0) = 1, "order-1 Y0");
   Check (Get_Y (G, 1) = 0, "order-1 Y1 before");
   Check (Next_Val (G) = 1, "order-1 first Next=1");
   Check (Get_Y (G, 0) = 1, "Y0 unchanged after Next");
   Check (Get_Y (G, 1) = 1, "Y1 after first");
   Check (Next_Val (G) = 2, "order-1 second Next=2");
   Check (Next_Val (G) = 3, "order-1 third Next=3");
   for I in 4 .. 15 loop
      Check (Next_Val (G) = V (Long_Long_Integer (I)),
             "order-1 Next=" & I'Image);
   end loop;
   Check (Next_Val (G) = 0, "order-1 wraps to 0");
   Check (Next_Val (G) = 1, "order-1 wraps to 1");

   -----------------------------------------------------------------
   Section ("3. Order-2 known hand sequence");
   -----------------------------------------------------------------
   G := Create (2, 16, Seeds_Of ([V (1), V (0), V (0)]));
   Check (Next_Val (G) = 1,  "k=2 step1");
   Check (Next_Val (G) = 3,  "k=2 step2");
   Check (Next_Val (G) = 6,  "k=2 step3");
   Check (Next_Val (G) = 10, "k=2 step4");
   Check (Next_Val (G) = 15, "k=2 step5");
   Check (Next_Val (G) = 5,  "k=2 step6");
   Check (Get_Y (G, 0) = 1, "k=2 Y0 still 1");
   Check (Get_Y (G, 1) = 6, "k=2 Y1 after 6");
   Check (Get_Y (G, 2) = 5, "k=2 Y2 after 6");

   -----------------------------------------------------------------
   Section ("4. Order-3 binomial-like from zero upper state");
   -----------------------------------------------------------------
   G := Create (3, 100, Seeds_Of ([V (1), V (0), V (0), V (0)]));
   Check (Next_Val (G) = 1,  "k=3 n=1");
   Check (Next_Val (G) = 4,  "k=3 n=2");
   Check (Next_Val (G) = 10, "k=3 n=3");
   Check (Next_Val (G) = 20, "k=3 n=4");
   Check (Next_Val (G) = 35, "k=3 n=5");
   Check (Next_Val (G) = 56, "k=3 n=6");
   Check (Next_Val (G) = 84, "k=3 n=7");
   Check (Next_Val (G) = 20, "k=3 n=8 (120 mod 100)");

   -----------------------------------------------------------------
   Section ("5. Reset replay and independent generators");
   -----------------------------------------------------------------
   G := Create (4, 97, Seeds_Of ([V (3), V (5), V (7), V (11), V (13)]));
   X := Next_Val (G);
   Y := Next_Val (G);
   Z := Next_Val (G);
   Reset (G, Seeds_Of ([V (3), V (5), V (7), V (11), V (13)]));
   Check (Next_Val (G) = X, "reset array replay 1");
   Check (Next_Val (G) = Y, "reset array replay 2");
   Check (Next_Val (G) = Z, "reset array replay 3");

   G := Create (5, Default_Modulus, V (42));
   G2 := Create (5, Default_Modulus, V (42));
   B := True;
   for I in 1 .. 20 loop
      if Next_Val (G) /= Next_Val (G2) then
         B := False;
      end if;
   end loop;
   Check (B, "independent identical seeds agree 20 draws");

   G := Create (3, 1000, V (7));
   G2 := Create (3, 1000, V (8));
   B := False;
   for I in 1 .. 10 loop
      if Next_Val (G) /= Next_Val (G2) then
         B := True;
      end if;
   end loop;
   Check (B, "different seeds diverge");

   -----------------------------------------------------------------
   Section ("6. LCG seed fill Create / Reset");
   -----------------------------------------------------------------
   G := Create (4, 1009, V (1));
   Check (Is_Initialised (G), "LCG Create initialised");
   Check (Order_Of (G) = 4, "LCG Create order");
   Check (Modulus_Of (G) = 1009, "LCG Create modulus");
   Copy_State (G, Buf);
   B := True;
   for I in 0 .. 4 loop
      if Buf (I) >= 1009 then
         B := False;
      end if;
   end loop;
   Check (B, "LCG fill all words < M");
   X := Next_Val (G);
   Y := Next_Val (G);
   Reset (G, V (1));
   Check (Next_Val (G) = X, "LCG Reset replay 1");
   Check (Next_Val (G) = Y, "LCG Reset replay 2");

   G := Create (3, 256, V (2));
   Check (Get_Y (G, 0) rem 2 = 1, "even M forces Y0 odd");

   -----------------------------------------------------------------
   Section ("7. Add_Mod helper");
   -----------------------------------------------------------------
   Check (Add_Mod (V (3), V (5), 7) = 1, "Add_Mod 3+5 mod 7");
   Check (Add_Mod (V (0), V (0), 2) = 0, "Add_Mod 0+0");
   Check (Add_Mod (V (15), V (1), 16) = 0, "Add_Mod wrap power2");
   M := Default_Modulus;
   Check (Add_Mod (M - 1, V (1), Modulus_Type (M)) = 0,
          "Add_Mod Default_Modulus wrap");
   Check (Add_Mod (M - 1, M - 1, Modulus_Type (M)) = M - 2,
          "Add_Mod (M-1)+(M-1)");
   for T in 1 .. 15 loop
      declare
         A  : constant Value := V (Long_Long_Integer (T * 7));
         Bv : constant Value := V (Long_Long_Integer (T * 11));
         Mm : constant Modulus_Type := 23;
      begin
         Check (Add_Mod (A rem Mm, Bv rem Mm, Mm) =
                  ((A rem Mm) + (Bv rem Mm)) rem Mm,
                "Add_Mod id t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("8. Uninitialised default");
   -----------------------------------------------------------------
   declare
      U : Generator;
   begin
      Check (Is_Initialised (U) = False, "default not initialised");
   end;

   -----------------------------------------------------------------
   Section ("9. Inspectors and Copy_State");
   -----------------------------------------------------------------
   G := Create (3, 64, Seeds_Of ([V (1), V (2), V (3), V (4)]));
   Check (Order_Of (G) = 3, "Order_Of 3");
   Check (Modulus_Of (G) = 64, "Modulus_Of 64");
   Check (Get_Y (G, 0) = 1, "Get_Y 0");
   Check (Get_Y (G, 3) = 4, "Get_Y 3");
   Copy_State (G, Buf);
   Check (Buf (0) = 1 and then Buf (1) = 2
          and then Buf (2) = 3 and then Buf (3) = 4,
          "Copy_State contents");
   X := Next_Val (G);
   Check (Get_Y (G, 3) = X, "Get_Y(k) equals last Next");

   -----------------------------------------------------------------
   Section ("10. Default_Modulus and Max_Order");
   -----------------------------------------------------------------
   declare
      Expected_M : Value := 1;
   begin
      for I in 1 .. 32 loop
         Expected_M := Expected_M * 2;
      end loop;
      Check (Default_Modulus = Expected_M, "Default_Modulus = 2^32");
      Check (Max_Modulus = Expected_M, "Max_Modulus = 2^32");
   end;
   Check (Nat (Max_Order) = Nat (64), "Max_Order = 64");
   G := Create (Max_Order, Default_Modulus, V (12345));
   Check (Order_Of (G) = Max_Order, "Create Max_Order");
   Check (Modulus_Of (G) = Default_Modulus, "Create Default_Modulus");
   X := Next_Val (G);
   Check (X < Default_Modulus, "Max_Order Next < M");

   -----------------------------------------------------------------
   Section ("11. Y0 stays fixed across many advances");
   -----------------------------------------------------------------
   G := Create (5, 1009,
                Seeds_Of ([V (17), V (0), V (0), V (0), V (0), V (0)]));
   for I in 1 .. 30 loop
      Discard := Next_Val (G);
   end loop;
   Check (Get_Y (G, 0) = 17, "Y0 fixed after 30 Next");

   -----------------------------------------------------------------
   Section ("12. Range: all outputs in [0, M)");
   -----------------------------------------------------------------
   for K in Order_Type range 1 .. 12 loop
      G := Create (K, 97, V (Long_Long_Integer (K) * 3));
      B := True;
      for I in 1 .. 40 loop
         if Next_Val (G) >= 97 then
            B := False;
         end if;
      end loop;
      Check (B, "range k=" & K'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("13. Power-of-two moduli smoke");
   -----------------------------------------------------------------
   for P in 2 .. 12 loop
      M := 2 ** P;
      G := Create (4, Modulus_Type (M), V (1));
      B := True;
      for I in 1 .. 20 loop
         X := Next_Val (G);
         if X >= M then
            B := False;
         end if;
      end loop;
      Check (B, "pow2 M=2^" & P'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("14. First output is 1 from [1,0,...,0]");
   -----------------------------------------------------------------
   for K in Order_Type range 1 .. 10 loop
      declare
         Seeds : State_Array := Zero_Seeds;
      begin
         Seeds (0) := 1;
         G := Create (K, 1000, Seeds);
         Check (Next_Val (G) = 1, "first out=1 k=" & K'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("15. Reset after many draws");
   -----------------------------------------------------------------
   G := Create (8, 10007, V (77));
   declare
      First : constant Value := Next_Val (G);
   begin
      for I in 1 .. 200 loop
         Discard := Next_Val (G);
      end loop;
      Reset (G, V (77));
      Check (Next_Val (G) = First, "reset after 200 draws");
   end;

   G := Create (3, 256, Seeds_Of ([V (1), V (2), V (3), V (4)]));
   X := Next_Val (G);
   for I in 1 .. 50 loop
      Discard := Next_Val (G);
   end loop;
   Reset (G, Seeds_Of ([V (1), V (2), V (3), V (4)]));
   Check (Next_Val (G) = X, "array reset after 50 draws");

   -----------------------------------------------------------------
   Section ("16. State inspect after advances");
   -----------------------------------------------------------------
   G := Create (2, 32, Seeds_Of ([V (5), V (7), V (11)]));
   Discard := Next_Val (G);
   Check (Get_Y (G, 0) = 5,  "inspect Y0");
   Check (Get_Y (G, 1) = 12, "inspect Y1");
   Check (Get_Y (G, 2) = 23, "inspect Y2");
   Copy_State (G, Buf);
   Check (Buf (0) = 5 and then Buf (1) = 12 and then Buf (2) = 23,
          "Copy_State after Next");

   -----------------------------------------------------------------
   Section ("17. Odd modulus LCG fill");
   -----------------------------------------------------------------
   G := Create (4, 1009, V (0));
   Check (Is_Initialised (G), "seed 0 odd M ok");
   B := True;
   for I in 0 .. 4 loop
      if Get_Y (G, I) >= 1009 then
         B := False;
      end if;
   end loop;
   Check (B, "seed 0 fill words < M");
   X := Next_Val (G);
   Check (X < 1009, "seed 0 Next < M");

   -----------------------------------------------------------------
   Section ("18. Varied Create smoke");
   -----------------------------------------------------------------
   for K in Order_Type range 1 .. 16 loop
      G := Create (K, 1009, V (Long_Long_Integer (K)));
      X := Next_Val (G);
      Check (X < 1009, "smoke k=" & K'Image);
   end loop;

   for M_Val in 2 .. 20 loop
      G := Create (2, Modulus_Type (V (Long_Long_Integer (M_Val))), V (1));
      B := True;
      for I in 1 .. 5 loop
         if Next_Val (G) >= V (Long_Long_Integer (M_Val)) then
            B := False;
         end if;
      end loop;
      Check (B, "smoke M=" & M_Val'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("19. Cross-check Add_Mod vs manual Next step");
   -----------------------------------------------------------------
   G := Create (3, 50, Seeds_Of ([V (9), V (4), V (2), V (7)]));
   declare
      Y0 : constant Value := Get_Y (G, 0);
      Y1 : constant Value := Get_Y (G, 1);
      Y2 : constant Value := Get_Y (G, 2);
      Y3 : constant Value := Get_Y (G, 3);
      N1 : constant Value := Add_Mod (Y1, Y0, 50);
      N2 : constant Value := Add_Mod (Y2, N1, 50);
      N3 : constant Value := Add_Mod (Y3, N2, 50);
   begin
      Check (Next_Val (G) = N3, "Next equals manual Add_Mod sweep");
      Check (Get_Y (G, 1) = N1, "Y1 after = N1");
      Check (Get_Y (G, 2) = N2, "Y2 after = N2");
      Check (Get_Y (G, 3) = N3, "Y3 after = N3");
   end;

   -----------------------------------------------------------------
   Section ("20. Two-generator interleaved independence");
   -----------------------------------------------------------------
   G := Create (4, 1024, V (11));
   G2 := Create (4, 1024, V (11));
   B := True;
   for I in 1 .. 15 loop
      X := Next_Val (G);
      if Next_Val (G2) /= X then
         B := False;
      end if;
   end loop;
   Check (B, "lockstep twins");
   for I in 1 .. 5 loop
      Discard := Next_Val (G);
   end loop;
   G2 := Create (4, 1024, V (11));
   Check (Next_Val (G) /= Next_Val (G2), "diverged after extra advances");

   -----------------------------------------------------------------
   Section ("21. More Add_Mod identities");
   -----------------------------------------------------------------
   for T in 1 .. 20 loop
      declare
         A  : constant Value := V (Long_Long_Integer (T * 13)) rem 29;
         Bv : constant Value := V (Long_Long_Integer (T * 17)) rem 29;
         Mm : constant Modulus_Type := 29;
      begin
         Check (Add_Mod (A, Bv, Mm) = Add_Mod (Bv, A, Mm),
                "Add_Mod commute t=" & T'Image);
         Check (Add_Mod (A, 0, Mm) = A, "Add_Mod +0 t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("22. Order-1 counter with various Y0");
   -----------------------------------------------------------------
   for S0 in 1 .. 7 loop
      G := Create (1, 16,
                   Seeds_Of ([V (Long_Long_Integer (S0)), V (0)]));
      Check (Next_Val (G) = V (Long_Long_Integer (S0)),
             "counter first=" & S0'Image);
      Check (Next_Val (G) = V (Long_Long_Integer ((2 * S0) rem 16)),
             "counter second=" & S0'Image);
   end loop;

   -----------------------------------------------------------------
   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
