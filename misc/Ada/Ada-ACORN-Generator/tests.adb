--  Standalone test suite for Acorn_Generator.

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Acorn_Generator;
use Acorn_Generator;

procedure Tests is

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

   function Create_Array_Raises
     (Order : Order_Type; M : Value; Seeds : State_Array) return Boolean
   is
      G : Generator;
   begin
      G := Create (Order, M, Seeds);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Array_Raises;

   function Create_Seed_Raises
     (Order : Order_Type; M : Value; Seed : Value) return Boolean
   is
      G : Generator;
   begin
      G := Create (Order, M, Seed);
      pragma Unreferenced (G);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Create_Seed_Raises;

   function Reset_Array_Raises
     (G : in out Generator; Seeds : State_Array) return Boolean
   is
   begin
      Reset (G, Seeds);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Array_Raises;

   function Reset_Seed_Raises
     (G : in out Generator; Seed : Value) return Boolean
   is
   begin
      Reset (G, Seed);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Seed_Raises;

   function Next_Raises (G : in out Generator) return Boolean is
      X : Value;
   begin
      X := Next (G);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Raises;

   function Next_Float_Raises (G : in out Generator) return Boolean is
      F : Long_Float;
   begin
      F := Next_Float (G);
      pragma Unreferenced (F);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Next_Float_Raises;

   function Order_Of_Raises (G : Generator) return Boolean is
      K : Order_Type;
   begin
      K := Order_Of (G);
      pragma Unreferenced (K);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Order_Of_Raises;

   function Modulus_Of_Raises (G : Generator) return Boolean is
      M : Value;
   begin
      M := Modulus_Of (G);
      pragma Unreferenced (M);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Modulus_Of_Raises;

   function Get_State_Raises (G : Generator) return Boolean is
      S : State_Array (0 .. 0);
   begin
      S := Get_State (G);
      pragma Unreferenced (S);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when Constraint_Error =>
         return True;
   end Get_State_Raises;

   function Get_Y_Raises (G : Generator; Index : Natural) return Boolean is
      X : Value;
   begin
      X := Get_Y (G, Index);
      pragma Unreferenced (X);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Y_Raises;

   function Add_Mod_Raises (X, Y, M : Value) return Boolean is
      R : Value;
   begin
      R := Add_Mod (X, Y, M);
      pragma Unreferenced (R);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Add_Mod_Raises;

   G, G2          : Generator;
   X, Y, Z, M     : Value;
   F              : Long_Float;
   B              : Boolean;
   Discard        : Value;
   pragma Unreferenced (Discard);

begin
   -----------------------------------------------------------------
   Section ("1. Invalid_Argument (bad modulus / seeds / length)");
   -----------------------------------------------------------------
   Check (Create_Seed_Raises (1, V (0), V (0)), "Create seed M=0");
   Check (Create_Seed_Raises (1, V (1), V (0)), "Create seed M=1");
   Check (Create_Array_Raises (2, V (0), [V (0), V (0), V (0)]),
          "Create array M=0");
   Check (Create_Array_Raises (2, V (1), [V (0), V (0), V (0)]),
          "Create array M=1");
   Check (Create_Seed_Raises (3, V (10), V (10)), "Create seed >= M");
   Check (Create_Seed_Raises (3, V (10), V (11)), "Create seed > M");
   Check (Create_Array_Raises (2, V (10), [V (1), V (2)]),
          "Create array length too short");
   Check (Create_Array_Raises (2, V (10), [V (1), V (2), V (3), V (4)]),
          "Create array length too long");
   Check (Create_Array_Raises (2, V (10), [V (1), V (10), V (3)]),
          "Create array seed >= M");
   Check (Add_Mod_Raises (V (1), V (2), V (0)), "Add_Mod M=0");
   Check (Is_Valid_Modulus (V (0)) = False, "Is_Valid_Modulus 0");
   Check (Is_Valid_Modulus (V (1)) = False, "Is_Valid_Modulus 1");
   Check (Is_Valid_Modulus (V (2)), "Is_Valid_Modulus 2");
   Check (Is_Valid_Order (Nat (1)), "Is_Valid_Order 1");
   Check (Is_Valid_Order (Nat (64)), "Is_Valid_Order 64");
   Check (Is_Valid_Order (Nat (65)) = False, "Is_Valid_Order 65");

   -----------------------------------------------------------------
   Section ("2. Tiny order-1 deterministic (Y0=1, Y1=0, M=16)");
   -----------------------------------------------------------------
   --  State [Y0, Y1] = [1, 0]. Next: Y1 ← (0+1) mod 16 = 1.
   --  Next again: Y1 ← (1+1) = 2. Sequence of Y1: 1,2,3,...,15,0,1,...
   G := Create (1, V (16), [V (1), V (0)]);
   Check (Order_Of (G) = 1, "order-1 Order_Of");
   Check (Modulus_Of (G) = 16, "order-1 Modulus_Of");
   Check (Get_Y (G, 0) = 1, "order-1 Y0");
   Check (Get_Y (G, 1) = 0, "order-1 Y1 before");
   Check (Next (G) = 1, "order-1 first Next=1");
   Check (Get_Y (G, 0) = 1, "Y0 unchanged after Next");
   Check (Get_Y (G, 1) = 1, "Y1 after first");
   Check (Next (G) = 2, "order-1 second Next=2");
   Check (Next (G) = 3, "order-1 third Next=3");
   for I in 4 .. 15 loop
      Check (Next (G) = V (Long_Long_Integer (I)),
             "order-1 Next=" & I'Image);
   end loop;
   Check (Next (G) = 0, "order-1 wraps to 0");
   Check (Next (G) = 1, "order-1 wraps to 1");

   -----------------------------------------------------------------
   Section ("3. Order-2 known hand sequence");
   -----------------------------------------------------------------
   --  Seeds [Y0,Y1,Y2] = [1, 0, 0], M=16.
   --  Step1: Y1=(0+1)=1; Y2=(0+1)=1  → output 1; state [1,1,1]
   --  Step2: Y1=(1+1)=2; Y2=(1+2)=3  → output 3; state [1,2,3]
   --  Step3: Y1=(2+1)=3; Y2=(3+3)=6  → output 6; state [1,3,6]
   --  Step4: Y1=(3+1)=4; Y2=(6+4)=10 → output 10
   --  Step5: Y1=(4+1)=5; Y2=(10+5)=15 → output 15
   --  Step6: Y1=(5+1)=6; Y2=(15+6)=5  → output 5
   G := Create (2, V (16), [V (1), V (0), V (0)]);
   Check (Next (G) = 1,  "k=2 step1");
   Check (Next (G) = 3,  "k=2 step2");
   Check (Next (G) = 6,  "k=2 step3");
   Check (Next (G) = 10, "k=2 step4");
   Check (Next (G) = 15, "k=2 step5");
   Check (Next (G) = 5,  "k=2 step6");
   Check (Get_Y (G, 0) = 1, "k=2 Y0 still 1");
   Check (Get_Y (G, 1) = 6, "k=2 Y1 after 6");
   Check (Get_Y (G, 2) = 5, "k=2 Y2 after 6");

   -----------------------------------------------------------------
   Section ("4. Order-3 binomial-like from zero upper state");
   -----------------------------------------------------------------
   --  Seeds [1,0,0,0], M=100. Outputs are binomial coefficients mod M:
   --  after n steps Y_k equals C(n+k-1, k) when Y0=1 and rest 0... actually
   --  for ACORN with Y0=1 fixed and Yi=0 initially, Yn^(k) = C(n+k-1, k)?
   --  Manual:
   --  n=1: Y1=1,Y2=1,Y3=1 → 1
   --  n=2: Y1=2,Y2=3,Y3=4 → 4
   --  n=3: Y1=3,Y2=6,Y3=10 → 10
   --  n=4: Y1=4,Y2=10,Y3=20 → 20
   G := Create (3, V (100), [V (1), V (0), V (0), V (0)]);
   Check (Next (G) = 1,  "k=3 n=1");
   Check (Next (G) = 4,  "k=3 n=2");
   Check (Next (G) = 10, "k=3 n=3");
   Check (Next (G) = 20, "k=3 n=4");
   Check (Next (G) = 35, "k=3 n=5");
   Check (Next (G) = 56, "k=3 n=6");
   Check (Next (G) = 84, "k=3 n=7");
   Check (Next (G) = 20, "k=3 n=8 (120 mod 100)");

   -----------------------------------------------------------------
   Section ("5. Reset replay and independent generators");
   -----------------------------------------------------------------
   G := Create (4, V (97), [V (3), V (5), V (7), V (11), V (13)]);
   X := Next (G);
   Y := Next (G);
   Z := Next (G);
   Reset (G, [V (3), V (5), V (7), V (11), V (13)]);
   Check (Next (G) = X, "reset array replay 1");
   Check (Next (G) = Y, "reset array replay 2");
   Check (Next (G) = Z, "reset array replay 3");

   G := Create (5, Default_Modulus, V (42));
   G2 := Create (5, Default_Modulus, V (42));
   B := True;
   for I in 1 .. 20 loop
      if Next (G) /= Next (G2) then
         B := False;
      end if;
   end loop;
   Check (B, "independent identical seeds agree 20 draws");

   G := Create (3, V (1000), V (7));
   G2 := Create (3, V (1000), V (8));
   B := False;
   for I in 1 .. 10 loop
      if Next (G) /= Next (G2) then
         B := True;
      end if;
   end loop;
   Check (B, "different seeds diverge");

   -----------------------------------------------------------------
   Section ("6. LCG seed fill Create / Reset");
   -----------------------------------------------------------------
   G := Create (4, V (1009), V (1));
   Check (Is_Initialised (G), "LCG Create initialised");
   Check (Order_Of (G) = 4, "LCG Create order");
   Check (Modulus_Of (G) = 1009, "LCG Create modulus");
   declare
      S : constant State_Array := Get_State (G);
   begin
      Check (S'Length = 5, "LCG state length Order+1");
      B := True;
      for I in S'Range loop
         if S (I) >= 1009 then
            B := False;
         end if;
      end loop;
      Check (B, "LCG fill all words < M");
   end;
   X := Next (G);
   Y := Next (G);
   Reset (G, V (1));
   Check (Next (G) = X, "LCG Reset replay 1");
   Check (Next (G) = Y, "LCG Reset replay 2");

   --  Even M forces Y0 odd.
   G := Create (3, V (256), V (2));
   Check (Get_Y (G, 0) rem 2 = 1, "even M forces Y0 odd");

   -----------------------------------------------------------------
   Section ("7. Next_Float in [0,1)");
   -----------------------------------------------------------------
   G := Create (6, V (10007), V (99));
   B := True;
   for I in 1 .. 50 loop
      F := Next_Float (G);
      if F < 0.0 or else F >= 1.0 then
         B := False;
      end if;
   end loop;
   Check (B, "50 floats in [0,1)");

   G := Create (1, V (8), [V (1), V (0)]);
   --  After Next, Y1=1 → 1/8 = 0.125
   F := Next_Float (G);
   Check (F = 0.125, "Next_Float 1/8");
   F := Next_Float (G);
   Check (F = 0.25, "Next_Float 2/8");
   F := Next_Float (G);
   Check (F = 0.375, "Next_Float 3/8");

   -----------------------------------------------------------------
   Section ("8. Add_Mod helper");
   -----------------------------------------------------------------
   Check (Add_Mod (V (3), V (5), V (7)) = 1, "Add_Mod 3+5 mod 7");
   Check (Add_Mod (V (0), V (0), V (2)) = 0, "Add_Mod 0+0");
   Check (Add_Mod (V (15), V (1), V (16)) = 0, "Add_Mod wrap power2");
   Check (Add_Mod (V (1), V (0), V (1)) = 0, "Add_Mod M=1");
   --  Overflow-safe: near 2^64-1
   M := Default_Modulus;
   Check (Add_Mod (M - 1, V (1), M) = 0, "Add_Mod Default_Modulus wrap");
   Check (Add_Mod (M - 1, M - 1, M) = M - 2,
          "Add_Mod (M-1)+(M-1)");
   declare
      Big : constant Value := Value'Last;
   begin
      Check (Add_Mod (Big, V (1), V (1009)) =
               (Big rem 1009 + 1) rem 1009,
             "Add_Mod near Value'Last");
   end;
   for T in 1 .. 15 loop
      declare
         A  : constant Value := V (Long_Long_Integer (T * 7));
         Bv : constant Value := V (Long_Long_Integer (T * 11));
         Mm : constant Value := V (23);
      begin
         Check (Add_Mod (A, Bv, Mm) = (A + Bv) rem Mm,
                "Add_Mod id t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("9. Uninitialised generator");
   -----------------------------------------------------------------
   declare
      U : Generator;
   begin
      Check (Is_Initialised (U) = False, "default not initialised");
      Check (Next_Raises (U), "Next uninit");
      Check (Next_Float_Raises (U), "Next_Float uninit");
      Check (Order_Of_Raises (U), "Order_Of uninit");
      Check (Modulus_Of_Raises (U), "Modulus_Of uninit");
      Check (Get_State_Raises (U), "Get_State uninit");
      Check (Get_Y_Raises (U, 0), "Get_Y uninit");
      Check (Reset_Seed_Raises (U, V (1)), "Reset seed uninit");
      Check (Reset_Array_Raises (U, [V (0), V (0)]), "Reset array uninit");
   end;

   -----------------------------------------------------------------
   Section ("10. Inspectors and Get_Y bounds");
   -----------------------------------------------------------------
   G := Create (3, V (64), [V (1), V (2), V (3), V (4)]);
   Check (Order_Of (G) = 3, "Order_Of 3");
   Check (Modulus_Of (G) = 64, "Modulus_Of 64");
   Check (Get_Y (G, 0) = 1, "Get_Y 0");
   Check (Get_Y (G, 3) = 4, "Get_Y 3");
   Check (Get_Y_Raises (G, 4), "Get_Y index > Order");
   Check (Get_Y_Raises (G, 99), "Get_Y index 99");
   declare
      S : constant State_Array := Get_State (G);
   begin
      Check (S'First = 0, "Get_State First=0");
      Check (S'Last = 3, "Get_State Last=Order");
      Check (S (0) = 1 and then S (1) = 2
             and then S (2) = 3 and then S (3) = 4,
             "Get_State contents");
   end;
   X := Next (G);
   Check (Get_Y (G, 3) = X, "Get_Y(k) equals last Next");

   -----------------------------------------------------------------
   Section ("11. Default_Modulus and Max_Order constants");
   -----------------------------------------------------------------
   declare
      Expected_M : Value := 1;
   begin
      for I in 1 .. 32 loop
         Expected_M := Expected_M * 2;
      end loop;
      Check (Default_Modulus = Expected_M, "Default_Modulus = 2^32");
   end;
   Check (Nat (Max_Order) = Nat (64), "Max_Order = 64");
   G := Create (Max_Order, Default_Modulus, V (12345));
   Check (Order_Of (G) = Max_Order, "Create Max_Order");
   Check (Modulus_Of (G) = Default_Modulus, "Create Default_Modulus");
   X := Next (G);
   Check (X < Default_Modulus, "Max_Order Next < M");
   F := Next_Float (G);
   Check (F >= 0.0 and then F < 1.0, "Max_Order Next_Float");

   -----------------------------------------------------------------
   Section ("12. Y0 stays fixed across many advances");
   -----------------------------------------------------------------
   G := Create (5, V (1009), [V (17), V (0), V (0), V (0), V (0), V (0)]);
   for I in 1 .. 30 loop
      Discard := Next (G);
   end loop;
   Check (Get_Y (G, 0) = 17, "Y0 fixed after 30 Next");

   -----------------------------------------------------------------
   Section ("13. Range: all outputs in [0, M)");
   -----------------------------------------------------------------
   for K in Order_Type range 1 .. 12 loop
      G := Create (K, V (97), V (Long_Long_Integer (K) * 3));
      B := True;
      for I in 1 .. 40 loop
         if Next (G) >= 97 then
            B := False;
         end if;
      end loop;
      Check (B, "range k=" & K'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("14. Power-of-two moduli smoke");
   -----------------------------------------------------------------
   for P in 2 .. 12 loop
      M := 2 ** P;
      G := Create (4, M, V (1));
      B := True;
      for I in 1 .. 20 loop
         X := Next (G);
         if X >= M then
            B := False;
         end if;
      end loop;
      Check (B, "pow2 M=2^" & P'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("15. More Invalid_Argument edges");
   -----------------------------------------------------------------
   G := Create (2, V (20), [V (1), V (2), V (3)]);
   Check (Reset_Seed_Raises (G, V (20)), "Reset seed = M");
   Check (Reset_Seed_Raises (G, V (21)), "Reset seed > M");
   Check (Reset_Array_Raises (G, [V (1), V (2)]),
          "Reset array wrong length");
   Check (Reset_Array_Raises (G, [V (1), V (2), V (20)]),
          "Reset array seed = M");
   Check (Create_Array_Raises
            (1, V (5), [V (0), V (5)]), "Create array Y1 = M");

   -----------------------------------------------------------------
   Section ("16. Deterministic multi-order batch from zero");
   -----------------------------------------------------------------
   --  For each k, seeds [1,0,...,0], M=1000, first output is always 1.
   for K in Order_Type range 1 .. 10 loop
      declare
         Seeds : State_Array (0 .. K) := [others => 0];
      begin
         Seeds (0) := 1;
         G := Create (K, V (1000), Seeds);
         Check (Next (G) = 1, "first out=1 k=" & K'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("17. Next_Float vs Next/M on small moduli");
   -----------------------------------------------------------------
   G := Create (2, V (16), [V (1), V (0), V (0)]);
   for I in 1 .. 8 loop
      declare
         Gf : Generator := Create (2, V (16), [V (1), V (0), V (0)]);
         Gi : Generator := Create (2, V (16), [V (1), V (0), V (0)]);
      begin
         for J in 1 .. I - 1 loop
            Discard := Next (Gf);
            Discard := Next (Gi);
         end loop;
         F := Next_Float (Gf);
         X := Next (Gi);
         Check (F = Long_Float (Long_Long_Integer (X)) / 16.0,
                "float vs int step " & I'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("18. Reset after many draws");
   -----------------------------------------------------------------
   G := Create (8, V (10007), V (77));
   declare
      First : constant Value := Next (G);
   begin
      for I in 1 .. 200 loop
         Discard := Next (G);
      end loop;
      Reset (G, V (77));
      Check (Next (G) = First, "reset after 200 draws");
   end;

   G := Create (3, V (256), [V (1), V (2), V (3), V (4)]);
   X := Next (G);
   for I in 1 .. 50 loop
      Discard := Next (G);
   end loop;
   Reset (G, [V (1), V (2), V (3), V (4)]);
   Check (Next (G) = X, "array reset after 50 draws");

   -----------------------------------------------------------------
   Section ("19. State inspect after advances");
   -----------------------------------------------------------------
   G := Create (2, V (32), [V (5), V (7), V (11)]);
   Discard := Next (G);
   --  Y1=(7+5)=12; Y2=(11+12)=23
   Check (Get_Y (G, 0) = 5,  "inspect Y0");
   Check (Get_Y (G, 1) = 12, "inspect Y1");
   Check (Get_Y (G, 2) = 23, "inspect Y2");
   declare
      S : constant State_Array := Get_State (G);
   begin
      Check (S (0) = 5 and then S (1) = 12 and then S (2) = 23,
             "Get_State after Next");
   end;

   -----------------------------------------------------------------
   Section ("20. Odd modulus LCG fill (no odd-force needed)");
   -----------------------------------------------------------------
   G := Create (4, V (1009), V (0));
   Check (Is_Initialised (G), "seed 0 odd M ok");
   B := True;
   for I in 0 .. 4 loop
      if Get_Y (G, I) >= 1009 then
         B := False;
      end if;
   end loop;
   Check (B, "seed 0 fill words < M");
   X := Next (G);
   Check (X < 1009, "seed 0 Next < M");

   -----------------------------------------------------------------
   Section ("21. Varied Create smoke padding");
   -----------------------------------------------------------------
   for K in Order_Type range 1 .. 16 loop
      G := Create (K, V (1009), V (Long_Long_Integer (K)));
      X := Next (G);
      Check (X < 1009, "smoke k=" & K'Image);
   end loop;

   for M_Val in 2 .. 20 loop
      G := Create (2, V (Long_Long_Integer (M_Val)), V (1));
      B := True;
      for I in 1 .. 5 loop
         if Next (G) >= V (Long_Long_Integer (M_Val)) then
            B := False;
         end if;
      end loop;
      Check (B, "smoke M=" & M_Val'Image);
   end loop;

   -----------------------------------------------------------------
   Section ("22. Cross-check Add_Mod vs manual Next step");
   -----------------------------------------------------------------
   G := Create (3, V (50), [V (9), V (4), V (2), V (7)]);
   declare
      Y0 : constant Value := Get_Y (G, 0);
      Y1 : constant Value := Get_Y (G, 1);
      Y2 : constant Value := Get_Y (G, 2);
      Y3 : constant Value := Get_Y (G, 3);
      N1 : constant Value := Add_Mod (Y1, Y0, 50);
      N2 : constant Value := Add_Mod (Y2, N1, 50);
      N3 : constant Value := Add_Mod (Y3, N2, 50);
   begin
      Check (Next (G) = N3, "Next equals manual Add_Mod sweep");
      Check (Get_Y (G, 1) = N1, "Y1 after = N1");
      Check (Get_Y (G, 2) = N2, "Y2 after = N2");
      Check (Get_Y (G, 3) = N3, "Y3 after = N3");
   end;

   -----------------------------------------------------------------
   Section ("23. Two-generator interleaved independence");
   -----------------------------------------------------------------
   G := Create (4, V (1024), V (11));
   G2 := Create (4, V (1024), V (11));
   B := True;
   for I in 1 .. 15 loop
      X := Next (G);
      if Next (G2) /= X then
         B := False;
      end if;
   end loop;
   Check (B, "lockstep twins");
   --  Advance only G, then they diverge from a fresh twin.
   for I in 1 .. 5 loop
      Discard := Next (G);
   end loop;
   G2 := Create (4, V (1024), V (11));
   Check (Next (G) /= Next (G2), "diverged after extra advances");

   -----------------------------------------------------------------
   Section ("24. More Add_Mod identities");
   -----------------------------------------------------------------
   for T in 1 .. 20 loop
      declare
         A  : constant Value := V (Long_Long_Integer (T * 13));
         Bv : constant Value := V (Long_Long_Integer (T * 17));
         Mm : constant Value := V (29);
      begin
         Check (Add_Mod (A, Bv, Mm) = Add_Mod (Bv, A, Mm),
                "Add_Mod commute t=" & T'Image);
         Check (Add_Mod (A, 0, Mm) = A rem Mm,
                "Add_Mod +0 t=" & T'Image);
      end;
   end loop;

   -----------------------------------------------------------------
   Section ("25. Order-1 counter with various Y0");
   -----------------------------------------------------------------
   for S0 in 1 .. 7 loop
      G := Create (1, V (16),
                   [V (Long_Long_Integer (S0)), V (0)]);
      Check (Next (G) = V (Long_Long_Integer (S0)),
             "counter first=" & S0'Image);
      Check (Next (G) = V (Long_Long_Integer ((2 * S0) rem 16)),
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
