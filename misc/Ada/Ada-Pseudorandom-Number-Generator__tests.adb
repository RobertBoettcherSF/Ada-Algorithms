--  Standalone test suite for Pseudorandom_Number_Generator (survey).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Interfaces;
with Pseudorandom_Number_Generator;
use Pseudorandom_Number_Generator;

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

   function Nat (X : Natural) return Natural is (X);
   function V (X : Long_Long_Integer) return Value is (Value (X));
   function LF (X : Long_Float) return Long_Float is (X);

   function Create_Raises
     (Engine : Kind; Seed : Value; Params : LCG_Parameters := Default_LCG)
      return Boolean
   is
      G : Generator;
   begin
      G := Create (Engine, Seed, Params);
      return not Is_Initialised (G);
   exception
      when Invalid_Argument =>
         return True;
   end Create_Raises;

   function Create_LCG_Raises
     (Seed : Value; Params : LCG_Parameters) return Boolean
   is
      G : Generator;
   begin
      G := Create_LCG (Seed, Params);
      return not Is_Initialised (G);
   exception
      when Invalid_Argument =>
         return True;
   end Create_LCG_Raises;

   function Create_XS_Raises (Seed : Value) return Boolean is
      G : Generator;
   begin
      G := Create_Xorshift (Seed);
      return not Is_Initialised (G);
   exception
      when Invalid_Argument =>
         return True;
   end Create_XS_Raises;

   function Reset_Raises (G : in out Generator; Seed : Value) return Boolean
   is
   begin
      Reset (G, Seed);
      return False;
   exception
      when Invalid_Argument =>
         return True;
   end Reset_Raises;

   function Next_Raises (G : in out Generator) return Boolean is
      X : Value;
   begin
      X := Next (G);
      return X = V (0) and then X = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end Next_Raises;

   function Next_Float_Raises (G : in out Generator) return Boolean is
      F : Long_Float;
   begin
      F := Next_Float (G);
      return F < LF (-1.0);
   exception
      when Invalid_Argument =>
         return True;
   end Next_Float_Raises;

   function LCG_Step_Raises
     (State : Value; Params : LCG_Parameters) return Boolean
   is
      X : Value;
   begin
      X := LCG_Step (State, Params);
      return X = V (0) and then X = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end LCG_Step_Raises;

   function XS_Step_Raises (State : Value) return Boolean is
      X : Value;
   begin
      X := Xorshift_Step (State);
      return X = V (0) and then X = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end XS_Step_Raises;

   function Add_Mod_Raises (A, B, M : Value) return Boolean is
      R : Value;
   begin
      R := Add_Mod (A, B, M);
      return R = V (0) and then R = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end Add_Mod_Raises;

   function Mul_Mod_Raises (A, B, M : Value) return Boolean is
      R : Value;
   begin
      R := Mul_Mod (A, B, M);
      return R = V (0) and then R = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end Mul_Mod_Raises;

   function Sub_Mod_Raises (A, B, M : Value) return Boolean is
      R : Value;
   begin
      R := Sub_Mod (A, B, M);
      return R = V (0) and then R = V (1);
   exception
      when Invalid_Argument =>
         return True;
   end Sub_Mod_Raises;

   function Get_Kind_Raises (G : Generator) return Boolean is
      K : Kind;
   begin
      K := Get_Kind (G);
      return K = LCG and then K = Xorshift;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Kind_Raises;

   function Get_Params_Raises (G : Generator) return Boolean is
      P : LCG_Parameters;
   begin
      P := Get_LCG_Parameters (G);
      return P.M = 0;
   exception
      when Invalid_Argument =>
         return True;
   end Get_Params_Raises;

   function Near
     (A, B : Long_Float; Tol : Long_Float := 1.0E-12) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   G, H : Generator;
   X, Y, Z : Value;
   F : Long_Float;
   P : LCG_Parameters;
   B : Boolean;
   Seen : array (0 .. 15) of Boolean;
   Period : Natural;

begin
   Section ("1. Uninitialised generator");
   Check (not Is_Initialised (G), "default not initialised");
   Check (Get_Kind_Raises (G), "Get_Kind uninit raises");
   Check (Next_Raises (G), "Next uninit raises");
   Check (Next_Float_Raises (G), "Next_Float uninit raises");
   Check (Reset_Raises (G, 1), "Reset uninit raises");

   Section ("2. Kind enumeration / Create dispatch");
   G := Create (LCG, 1);
   Check (Is_Initialised (G), "Create LCG initialised");
   Check (Get_Kind (G) = LCG, "kind LCG");
   Check (Get_Seed (G) = 1, "seed 1");
   G := Create_Lagged_Fibonacci (42);
   Check (Get_Kind (G) = Lagged_Fibonacci, "kind LFG");
   Check (Get_Seed (G) = 42, "LFG seed");
   G := Create_Xorshift (7);
   Check (Get_Kind (G) = Xorshift, "kind Xorshift");
   Check (Get_Seed (G) = 7, "XS seed");
   G := Create (Lagged_Fibonacci, 0);
   Check (Get_Kind (G) = Lagged_Fibonacci, "LFG seed 0 ok");
   G := Create (Xorshift, Value'Last);
   Check (Get_Kind (G) = Xorshift, "XS seed Value'Last");

   Section ("3. LCG Invalid_Argument");
   P := (A => 0, C => 1, M => 0);
   Check (not Is_Valid_LCG_Parameters (P), "M=0 invalid");
   Check (Create_LCG_Raises (0, P), "Create M=0 raises");
   P := (A => 1, C => 0, M => 1);
   Check (not Is_Valid_LCG_Parameters (P), "M=1 invalid");
   Check (Create_LCG_Raises (0, P), "Create M=1 raises");
   P := (A => 0, C => 1, M => 10);
   Check (not Is_Valid_LCG_Parameters (P), "A=0 invalid");
   Check (Create_LCG_Raises (0, P), "Create A=0 raises");
   P := (A => 10, C => 1, M => 10);
   Check (not Is_Valid_LCG_Parameters (P), "A rem M = 0 invalid");
   P := (A => 4, C => 1, M => 9);
   Check (Is_Valid_LCG_Parameters (P), "m=9 a=4 valid");
   Check (Create_LCG_Raises (9, P), "seed >= M raises");
   Check (Create_LCG_Raises (10, P), "seed > M raises");
   Check (not Create_LCG_Raises (0, P), "seed 0 ok");
   Check (not Create_LCG_Raises (8, P), "seed M-1 ok");
   Check (Create_Raises (LCG, 9, P), "Create Kind LCG seed>=M");
   Check (LCG_Step_Raises (9, P), "LCG_Step state>=M");
   Check (LCG_Step_Raises (0, (A => 0, C => 0, M => 0)), "LCG_Step M=0");

   Section ("4. Xorshift seed / step rejects zero");
   Check (Create_XS_Raises (0), "Create_Xorshift 0 raises");
   Check (Create_Raises (Xorshift, 0), "Create Kind XS 0 raises");
   Check (XS_Step_Raises (0), "Xorshift_Step 0 raises");
   Check (not XS_Step_Raises (1), "Xorshift_Step 1 ok");

   Section ("5. Modular helpers");
   Check (Add_Mod_Raises (1, 1, 0), "Add_Mod M=0");
   Check (Mul_Mod_Raises (1, 1, 0), "Mul_Mod M=0");
   Check (Sub_Mod_Raises (1, 1, 0), "Sub_Mod M=0");
   Check (Add_Mod (3, 4, 5) = 2, "3+4 mod 5 = 2");
   Check (Add_Mod (4, 4, 5) = 3, "4+4 mod 5 = 3");
   Check (Add_Mod (0, 0, 2) = 0, "0+0 mod 2");
   Check (Add_Mod (1, 0, 1) = 0, "mod 1 -> 0");
   Check (Mul_Mod (6, 7, 10) = 2, "6*7 mod 10 = 2");
   Check (Mul_Mod (0, 5, 9) = 0, "0*5 mod 9");
   Check (Mul_Mod (V (2 ** 32), V (2 ** 32), V (2 ** 32 + 1)) = V (1),
          "2^32^2 rem (2^32+1) via 128-bit");
   Check (Sub_Mod (3, 5, 7) = 5, "3-5 mod 7 = 5");
   Check (Sub_Mod (5, 3, 7) = 2, "5-3 mod 7 = 2");
   Check (Sub_Mod (0, 0, 11) = 0, "0-0");
   Check (Sub_Mod (1, 1, 1) = 0, "sub mod 1");

   Section ("6. Tiny LCG m=9 full period");
   P := (A => 4, C => 1, M => 9);
   G := Create_LCG (0, P);
   Check (Get_State (G) = 0, "state after create = seed");
   Check (Next (G) = 1, "X1=1");
   Check (Next (G) = 5, "X2=5");
   Check (Next (G) = 3, "X3=3");
   Check (Next (G) = 4, "X4=4");
   Check (Next (G) = 8, "X5=8");
   Check (Next (G) = 6, "X6=6");
   Check (Next (G) = 7, "X7=7");
   Check (Next (G) = 2, "X8=2");
   Check (Next (G) = 0, "X9=0 period");
   Check (Next (G) = 1, "X10=1 wraps");

   Section ("7. LCG_Step matches Next");
   P := (A => 4, C => 1, M => 9);
   G := Create_LCG (0, P);
   X := 0;
   B := True;
   for Step_I in 1 .. 20 loop
      Y := LCG_Step (X, P);
      Z := Next (G);
      if Y /= Z then
         B := False;
      end if;
      X := Y;
   end loop;
   Check (B, "LCG_Step equiv Next for 20 steps");

   Section ("8. Numerical Recipes / glibc / Park-Miller smoke");
   G := Create_LCG (1, Numerical_Recipes);
   Check (Get_LCG_Parameters (G).A = Numerical_Recipes.A, "NR A");
   Check (Get_LCG_Parameters (G).M = Numerical_Recipes.M, "NR M");
   X := Next (G);
   Y := Next (G);
   Check (X /= Y, "NR two samples differ");
   Check (X < Numerical_Recipes.M and Y < Numerical_Recipes.M, "NR < M");
   G := Create (LCG, 12345, Glibc);
   Check (Get_LCG_Parameters (G).M = Glibc.M, "glibc M");
   X := Next (G);
   Check (X < Glibc.M, "glibc sample < M");
   G := Create_LCG (1, Park_Miller);
   Check (Get_LCG_Parameters (G).C = 0, "Park-Miller MCG");
   X := Next (G);
   Check (X = 16_807, "Park-Miller X1=16807");
   Check (LCG_Step (1, Park_Miller) = 16_807, "LCG_Step Park-Miller");

   Section ("9. MCG seed 0 fixed point");
   G := Create_LCG (0, Park_Miller);
   Check (Next (G) = 0, "MCG seed 0 -> 0");
   Check (Next (G) = 0, "MCG stays 0");

   Section ("10. Reset reproducibility LCG");
   G := Create_LCG (99, Glibc);
   declare
      Buf : array (1 .. 8) of Value;
   begin
      for Idx in Buf'Range loop
         Buf (Idx) := Next (G);
      end loop;
      Reset (G, 99);
      B := True;
      for Idx in Buf'Range loop
         if Next (G) /= Buf (Idx) then
            B := False;
         end if;
      end loop;
      Check (B, "glibc reset replay");
   end;
   G := Create_LCG (12345, Numerical_Recipes);
   X := Next (G);
   Y := Next (G);
   Reset (G, 12345);
   Check (Next (G) = X and then Next (G) = Y, "NR reset replay");
   G := Create_LCG (0, P);
   Check (Reset_Raises (G, 9), "Reset seed>=M raises");

   Section ("11. Independent generators");
   G := Create_LCG (5, Numerical_Recipes);
   H := Create_LCG (5, Numerical_Recipes);
   B := True;
   for Step_I in 1 .. 16 loop
      if Next (G) /= Next (H) then
         B := False;
      end if;
   end loop;
   Check (B, "identical seeds -> identical streams");
   G := Create_LCG (5, Numerical_Recipes);
   H := Create_LCG (6, Numerical_Recipes);
   Check (Next (G) /= Next (H), "different seeds diverge");

   Section ("12. Next_Float LCG in [0,1)");
   P := (A => 1, C => 1, M => 8);
   G := Create_LCG (0, P);
   B := True;
   for Step_I in 0 .. 7 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "counter floats in [0,1)");
   Reset (G, 0);
   F := Next_Float (G);
   Check (Near (F, LF (1.0 / 8.0)), "first float = 1/8");
   for Step_I in 1 .. 7 loop
      F := Next_Float (G);
   end loop;
   Check (Near (F, LF (0.0)), "wrap float = 0.0");
   G := Create_LCG (0, (A => 4, C => 1, M => 9));
   B := True;
   for Step_I in 1 .. 50 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "50 LCG floats in [0,1)");

   Section ("13. Reduce_LCG");
   P := (A => 25, C => 15, M => 10);
   declare
      R : constant LCG_Parameters := Reduce_LCG (P);
   begin
      Check (R.A = 5 and R.C = 5 and R.M = 10, "Reduce 25,15,10");
   end;
   P := (A => 1, C => 0, M => 0);
   begin
      P := Reduce_LCG (P);
      Check (False, "Reduce M=0 should raise");
   exception
      when Invalid_Argument =>
         Check (True, "Reduce M=0 raises");
   end;

   Section ("14. Lagged Fibonacci basic");
   Check (Nat (LFG_J) = 7, "LFG_J=7");
   Check (Nat (LFG_K) = 10, "LFG_K=10");
   Check (LFG_Modulus > V (2 ** 16), "LFG_Modulus > 2^16");
   Check (LFG_Modulus = V (4_294_967_296), "LFG_Modulus = 2^32");
   G := Create_Lagged_Fibonacci (1);
   Check (Is_Initialised (G), "LFG init");
   X := Next (G);
   Y := Next (G);
   Check (X < LFG_Modulus and Y < LFG_Modulus, "LFG samples < M");
   Check (X /= Y, "LFG first two differ (typical)");

   G := Create_Lagged_Fibonacci (123);
   declare
      Buf : array (1 .. 32) of Value;
   begin
      for Idx in Buf'Range loop
         Buf (Idx) := Next (G);
      end loop;
      Reset (G, 123);
      B := True;
      for Idx in Buf'Range loop
         if Next (G) /= Buf (Idx) then
            B := False;
         end if;
      end loop;
      Check (B, "LFG reset replay 32");
   end;
   G := Create (Lagged_Fibonacci, 0);
   H := Create_Lagged_Fibonacci (0);
   B := True;
   for Step_I in 1 .. 20 loop
      if Next (G) /= Next (H) then
         B := False;
      end if;
   end loop;
   Check (B, "Create Kind LFG equiv Create_Lagged_Fibonacci");

   Section ("15. LFG Next_Float and Get_State");
   G := Create_Lagged_Fibonacci (99);
   B := True;
   for Step_I in 1 .. 40 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "40 LFG floats in [0,1)");
   G := Create_Lagged_Fibonacci (5);
   X := Next (G);
   Check (Get_State (G) = X, "LFG Get_State = last Next");
   Check (Get_Params_Raises (G), "Get_LCG_Parameters on LFG raises");

   Section ("16. Xorshift sequences");
   G := Create_Xorshift (1);
   Check (Get_State (G) = 1, "XS state = seed before Next");
   X := Next (G);
   Check (X = Xorshift_Step (1), "Next equiv Xorshift_Step(seed)");
   Check (Get_State (G) = X, "XS Get_State after Next");
   Y := Xorshift_Step (X);
   Check (Next (G) = Y, "second Next equiv step");
   declare
      use Interfaces;
      T : Unsigned_64 := 1;
   begin
      T := T xor Shift_Left (T, 13);
      T := T xor Shift_Right (T, 7);
      T := T xor Shift_Left (T, 17);
      Check (X = Value (T), "XS seed1 first = hand-computed");
   end;
   G := Create_Xorshift (1);
   declare
      Buf : array (1 .. 16) of Value;
   begin
      for Idx in Buf'Range loop
         Buf (Idx) := Next (G);
      end loop;
      Reset (G, 1);
      B := True;
      for Idx in Buf'Range loop
         if Next (G) /= Buf (Idx) then
            B := False;
         end if;
      end loop;
      Check (B, "XS reset replay");
   end;
   G := Create_Xorshift (123456789);
   B := True;
   for Step_I in 1 .. 200 loop
      if Next (G) = 0 then
         B := False;
      end if;
   end loop;
   Check (B, "XS never 0 in 200 steps");
   G := Create_Xorshift (1);
   Check (Reset_Raises (G, 0), "XS Reset 0 raises");

   Section ("17. Xorshift Next_Float");
   G := Create_Xorshift (42);
   B := True;
   for Step_I in 1 .. 50 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "50 XS floats in [0,1)");
   G := Create_Xorshift (1);
   X := Next (G);
   Reset (G, 1);
   F := Next_Float (G);
   Check (Near (F, Long_Float (X) / (2.0 ** 64)), "XS float = X/2^64");
   Check (Get_Params_Raises (G), "Get_LCG_Parameters on XS raises");

   Section ("18. Cross-kind isolation");
   G := Create_LCG (1);
   H := Create_Xorshift (1);
   Check (Get_Kind (G) = LCG, "still LCG");
   Check (Get_Kind (H) = Xorshift, "still XS");
   Check (Get_Kind (G) /= Get_Kind (H), "LCG /= XS kind");
   G := Create_Lagged_Fibonacci (1);
   H := Create_Xorshift (1);
   Check (Get_Kind (G) = Lagged_Fibonacci, "still LFG");
   Check (Get_Kind (H) = Xorshift, "still XS 2");

   Section ("19. Built-in parameter validity");
   Check (Is_Valid_LCG_Parameters (Numerical_Recipes), "NR valid");
   Check (Is_Valid_LCG_Parameters (Glibc), "glibc valid");
   Check (Is_Valid_LCG_Parameters (Park_Miller), "Park-Miller valid");
   Check (Is_Valid_LCG_Parameters (Default_LCG), "Default_LCG valid");
   Check (Default_LCG.A = Numerical_Recipes.A, "Default = NR");
   G := Create (LCG, 0);
   Check (Get_LCG_Parameters (G).M = Numerical_Recipes.M, "Create default NR");

   Section ("20. Period of tiny LCG m=8");
   P := (A => 5, C => 1, M => 8);
   G := Create_LCG (0, P);
   for J in Seen'Range loop
      Seen (J) := False;
   end loop;
   Period := 0;
   B := True;
   for Step_I in 1 .. 16 loop
      X := Next (G);
      if X > 7 then
         B := False;
      end if;
      if not Seen (Natural (X)) then
         Seen (Natural (X)) := True;
         Period := Period + 1;
      end if;
   end loop;
   Check (B, "m=8 samples in range");
   Check (Period = Nat (8), "m=8 visits all 8 residues");

   Section ("21. Determinism across Create aliases");
   G := Create (LCG, 77, Glibc);
   H := Create_LCG (77, Glibc);
   B := True;
   for Step_I in 1 .. 12 loop
      if Next (G) /= Next (H) then
         B := False;
      end if;
   end loop;
   Check (B, "Create equiv Create_LCG");
   G := Create (Xorshift, 99);
   H := Create_Xorshift (99);
   B := True;
   for Step_I in 1 .. 12 loop
      if Next (G) /= Next (H) then
         B := False;
      end if;
   end loop;
   Check (B, "Create equiv Create_Xorshift");

   Section ("22. Many LCG floats smoke");
   G := Create_LCG (123, Numerical_Recipes);
   B := True;
   for Step_I in 1 .. 100 loop
      Y := Next (G);
      F := Long_Float (Y) / Long_Float (Numerical_Recipes.M);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "100 NR scaled floats in [0,1)");

   Section ("23. LFG Get_State tracks Next");
   G := Create_Lagged_Fibonacci (777);
   B := True;
   for Step_I in 1 .. 15 loop
      X := Next (G);
      if Get_State (G) /= X then
         B := False;
      end if;
   end loop;
   Check (B, "LFG state tracks 15 Next calls");

   Section ("24. Inspector edges");
   G := Create_LCG (3, (A => 2, C => 3, M => 11));
   Check (Get_Seed (G) = 3, "seed 3");
   Check (Get_State (G) = 3, "state=seed before Next");
   X := Next (G);
   Check (Get_State (G) = X, "state after");
   Check (Get_Kind (G) = LCG, "kind still LCG");
   P := Get_LCG_Parameters (G);
   Check (P.A = 2 and P.C = 3 and P.M = 11, "params retained");

   Section ("25. Overflow-safe Mul_Mod stress");
   Check (Mul_Mod (Value'Last, Value'Last, Value'Last) = 0,
          "max*max mod max = 0");
   Check (Mul_Mod (3, 5, 7) = 1, "15 mod 7 = 1");
   Check (Add_Mod (Value'Last, 1, Value'Last) = 1, "Add near full width");
   Check (Sub_Mod (0, 1, 10) = 9, "0-1 mod 10");

   Section ("26. Kind round-trip table");
   declare
      Engines : constant array (1 .. 3) of Kind :=
        [LCG, Lagged_Fibonacci, Xorshift];
   begin
      for Idx in Engines'Range loop
         G := Create (Engines (Idx), 1);
         Check (Get_Kind (G) = Engines (Idx), "table kind");
         Check (Is_Initialised (G), "table init");
         X := Next (G);
         F := Next_Float (G);
         Check (F >= LF (0.0) and then F < LF (1.0), "table float");
         Check (Get_Seed (G) = 1, "table seed stable");
      end loop;
   end;

   Section ("27. Long reset chains");
   G := Create_Xorshift (55);
   for Round in 1 .. 5 loop
      declare
         Buf : array (1 .. 10) of Value;
         Label : constant String := "XS multi-reset";
      begin
         for Idx in Buf'Range loop
            Buf (Idx) := Next (G);
         end loop;
         Reset (G, 55);
         B := True;
         for Idx in Buf'Range loop
            if Next (G) /= Buf (Idx) then
               B := False;
            end if;
         end loop;
         Check (B, Label);
         Reset (G, 55);
      end;
   end loop;

   Section ("28. Park-Miller short known sequence");
   G := Create_LCG (1, Park_Miller);
   Check (Next (G) = 16_807, "PM 1");
   X := Mul_Mod (16_807, 16_807, Park_Miller.M);
   Check (Next (G) = X, "PM 2 = 16807^2 mod m");

   Section ("29. LCG float endpoints counter m=4");
   P := (A => 1, C => 1, M => 4);
   G := Create_LCG (3, P);
   F := Next_Float (G);
   Check (Near (F, LF (0.0)), "m=4 from 3 -> 0.0");
   F := Next_Float (G);
   Check (Near (F, LF (0.25)), "-> 1/4");
   F := Next_Float (G);
   Check (Near (F, LF (0.5)), "-> 2/4");
   F := Next_Float (G);
   Check (Near (F, LF (0.75)), "-> 3/4");

   Section ("30. Smoke volume across engines");
   G := Create_LCG (999, Numerical_Recipes);
   H := Create_Lagged_Fibonacci (999);
   declare
      XS : Generator := Create_Xorshift (999);
      C1, C2, C3 : Natural := 0;
   begin
      for Step_I in 1 .. 64 loop
         X := Next (G);
         Y := Next (H);
         Z := Next (XS);
         if X rem 2 = 0 then
            C1 := C1 + 1;
         end if;
         if Y rem 2 = 0 then
            C2 := C2 + 1;
         end if;
         if Z rem 2 = 0 then
            C3 := C3 + 1;
         end if;
      end loop;
      Check (C1 > Nat (0) and C1 < Nat (64), "NR not all odd/even");
      Check (C2 > Nat (0) and C2 < Nat (64), "LFG not all odd/even");
      Check (C3 > Nat (0) and C3 < Nat (64), "XS not all odd/even");
   end;

   Section ("31. More Invalid_Argument edges");
   P := (A => 1, C => 0, M => 2);
   Check (Is_Valid_LCG_Parameters (P), "minimal MCG valid");
   G := Create_LCG (0, P);
   Check (Next (G) = 0, "minimal MCG stays");
   Check (Create_LCG_Raises (2, P), "seed=M raises");
   Check (LCG_Step_Raises (2, P), "step state=M");
   Check (Add_Mod (1, 1, 2) = 0, "1+1 mod 2");
   Check (Mul_Mod (3, 3, 2) = 1, "9 mod 2");
   declare
      U : Generator;
   begin
      Check (Next_Float_Raises (U), "uninit Next_Float");
   end;

   Section ("32. Batch Next equality LCG_Step chain");
   P := (A => 7, C => 3, M => 13);
   G := Create_LCG (2, P);
   X := 2;
   B := True;
   for Step_I in 1 .. 40 loop
      X := LCG_Step (X, P);
      if Next (G) /= X then
         B := False;
      end if;
   end loop;
   Check (B, "40-step LCG_Step chain");

   Section ("33. XS hand steps chain");
   X := 9;
   G := Create_Xorshift (9);
   B := True;
   for Step_I in 1 .. 30 loop
      X := Xorshift_Step (X);
      if Next (G) /= X then
         B := False;
      end if;
   end loop;
   Check (B, "30-step XS chain");

   Section ("34. Constants documentation anchors");
   Check (Nat (XS_A) = 13, "XS_A=13");
   Check (Nat (XS_B) = 7, "XS_B=7");
   Check (Nat (XS_C) = 17, "XS_C=17");
   Check (Numerical_Recipes.C = 1_013_904_223, "NR C");
   Check (Glibc.A = 1_103_515_245, "glibc A");
   Check (Park_Miller.A = 16_807, "PM A");
   Check (Park_Miller.M = V (2 ** 31 - 1), "PM M");

   Section ("35. Final multi-engine float sweep");
   B := True;
   G := Create_LCG (11, Glibc);
   for Step_I in 1 .. 25 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "glibc floats ok");
   B := True;
   G := Create_Lagged_Fibonacci (11);
   for Step_I in 1 .. 25 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "LFG floats ok");
   B := True;
   G := Create_Xorshift (11);
   for Step_I in 1 .. 25 loop
      F := Next_Float (G);
      if F < LF (0.0) or else F >= LF (1.0) then
         B := False;
      end if;
   end loop;
   Check (B, "XS floats ok");

   Section ("36. Extra LCG period and Reduce edges");
   P := (A => 4, C => 1, M => 9);
   G := Create_LCG (5, P);
   --  From seed 5 the sequence continues mid-cycle: 5 already is X2
   --  of the seed-0 stream; next is 3.
   Check (Next (G) = 3, "m=9 from seed 5 -> 3");
   Check (Next (G) = 4, "then 4");
   P := Reduce_LCG ((A => 100, C => 50, M => 9));
   Check (P.A = 1 and P.C = 5 and P.M = 9, "Reduce 100,50,9");
   Check (Is_Valid_LCG_Parameters (P), "reduced still valid");

   Section ("37. LFG vs LCG sample streams differ");
   G := Create_LCG (42, Numerical_Recipes);
   H := Create_Lagged_Fibonacci (42);
   B := False;
   for Step_I in 1 .. 8 loop
      if Next (G) /= Next (H) then
         B := True;
      end if;
   end loop;
   Check (B, "LFG and LCG streams differ");

   Section ("38. Get_Seed stable across Next");
   G := Create_Xorshift (77);
   Check (Get_Seed (G) = 77, "XS seed before");
   X := Next (G);
   Check (Get_Seed (G) = 77, "XS seed after Next");
   G := Create_LCG (12, Glibc);
   X := Next (G);
   Y := Next (G);
   Check (Get_Seed (G) = 12, "LCG seed stable");
   G := Create_Lagged_Fibonacci (8);
   X := Next (G);
   Check (Get_Seed (G) = 8, "LFG seed stable");

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
             & " FAIL");
   if Fail_Count /= 0 then
      raise Program_Error with "test failures";
   end if;
end Tests;
