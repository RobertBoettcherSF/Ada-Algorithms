--  Standalone test suite for Pollards_Kangaroo_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Pollards_Kangaroo_Algorithm; use Pollards_Kangaroo_Algorithm;

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

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function U (X : U64) return U64 is (X);
   function Nat (X : Natural) return Natural is (X);

   ------------------------------------------------------------------
   --  Tiny brute-force oracle (tests only; not exported)
   ------------------------------------------------------------------

   function Brute_Force_DL
     (G, Y, P, A, B : U64) return Kangaroo_Result
   is
      R : Kangaroo_Result;
      X : U64 := A;
   begin
      loop
         if Mod_Exp (G, X, P) = (Y rem P) then
            R.Found := True;
            R.X     := X;
            return R;
         end if;
         exit when X = B;
         X := X + 1;
      end loop;
      return R;
   end Brute_Force_DL;

   procedure Expect_Invalid_Mul_Mod (Label : String; A, B, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mul_Mod (A, B, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mul_Mod: " & Label);
   end Expect_Invalid_Mul_Mod;

   procedure Expect_Invalid_Mod_Exp (Label : String; B, E, M : U64) is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 := Mod_Exp (B, E, M);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Mod_Exp: " & Label);
   end Expect_Invalid_Mod_Exp;

   procedure Expect_Invalid_Solve
     (Label : String; P, G, Y, A, B : U64; Max_Steps : Natural := 10_000)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Solve_Kangaroo (P, G, Y, A, B, Max_Steps);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Solve: " & Label);
   end Expect_Invalid_Solve;

   procedure Expect_Not_Found
     (Label : String; P, G, Y, A, B : U64; Max_Steps : Natural)
   is
      Raised : Boolean := False;
   begin
      begin
         declare
            Unused : constant U64 :=
              Solve_Kangaroo (P, G, Y, A, B, Max_Steps);
            pragma Unreferenced (Unused);
         begin
            null;
         end;
      exception
         when Not_Found =>
            Raised := True;
      end;
      Check (Raised, "Not_Found: " & Label);
   end Expect_Not_Found;

   procedure Check_Instance
     (Label : String; P, G, Y, A, B, Expected : U64)
   is
      R : Kangaroo_Result;
      X : U64;
   begin
      R := Try_Solve_Kangaroo (P, G, Y, A, B);
      Check (R.Found, Label & " found");
      if R.Found then
         Check (R.X = Expected, Label & " X matches expected");
         Check (R.X >= A and then R.X <= B, Label & " X in [A,B]");
         Check (Verify_Discrete_Log (G, Y, P, R.X),
                Label & " verify G^X ≡ Y");
         Check (Mod_Exp (G, R.X, P) = (Y rem P),
                Label & " Mod_Exp(G,X,P)=Y");
         X := Solve_Kangaroo (P, G, Y, A, B);
         Check (X = Expected, Label & " Solve_Kangaroo = expected");
      else
         Check (False, Label & " X matches expected");
         Check (False, Label & " X in [A,B]");
         Check (False, Label & " verify G^X ≡ Y");
         Check (False, Label & " Mod_Exp(G,X,P)=Y");
         Check (False, Label & " Solve_Kangaroo = expected");
      end if;
   end Check_Instance;

   procedure Check_Against_Oracle
     (Label : String; P, G, Y, A, B : U64)
   is
      Oracle : constant Kangaroo_Result := Brute_Force_DL (G, Y, P, A, B);
      R      : Kangaroo_Result;
   begin
      R := Try_Solve_Kangaroo (P, G, Y, A, B);
      if Oracle.Found then
         Check (R.Found, Label & " kangaroo finds oracle hit");
         if R.Found then
            --  Multiple logs may exist when G has small order; accept any
            --  verified X in [A, B] (oracle returns the least).
            Check (R.X >= A and then R.X <= B, Label & " X in interval");
            Check (Verify_Discrete_Log (G, Y, P, R.X),
                   Label & " oracle-path verify");
         else
            Check (False, Label & " X in interval");
            Check (False, Label & " oracle-path verify");
         end if;
      else
         Check (not R.Found, Label & " both miss (no DL in interval)");
      end if;
   end Check_Against_Oracle;

   R : Kangaroo_Result;
   X : U64;

begin
   Ada.Text_IO.Put_Line
     ("Pollards_Kangaroo_Algorithm — Ada 2023 test suite");

   ------------------------------------------------------------------
   Section ("1. Mul_Mod / Mod_Exp / Floor_Sqrt");
   ------------------------------------------------------------------
   Check (Mul_Mod (U (7), U (6), U (10)) = 2, "7*6 mod 10 = 2");
   Check (Mul_Mod (U (0), U (5), U (9)) = 0, "0*5 mod 9 = 0");
   Check (Mul_Mod (U (2), U (3), U (1)) = 0, "any mod 1 = 0");
   Check (Mul_Mod (U (2), U (5), U (1019)) = 10, "2*5 mod 1019");
   Check (Mul_Mod (U (123456789), U (987654321), U (1_000_000_007)) =
            259_106_859,
          "big Mul_Mod");

   Check (Mod_Exp (U (2), U (10), U (1019)) = 5, "2^10 ≡ 5 (mod 1019)");
   Check (Mod_Exp (U (5), U (6), U (23)) = 8, "5^6 ≡ 8 (mod 23)");
   Check (Mod_Exp (U (2), U (8), U (101)) = 54, "2^8 ≡ 54 (mod 101)");
   Check (Mod_Exp (U (3), U (0), U (17)) = 1, "3^0 ≡ 1");
   Check (Mod_Exp (U (3), U (1), U (17)) = 3, "3^1 ≡ 3");
   Check (Mod_Exp (U (7), U (2), U (13)) = 10, "7^2 ≡ 10 (mod 13)");
   Check (Mod_Exp (U (2), U (0), U (1)) = 0, "any^exp mod 1 = 0");

   Check (Floor_Sqrt (U (0)) = 0, "√0 = 0");
   Check (Floor_Sqrt (U (1)) = 1, "√1 = 1");
   Check (Floor_Sqrt (U (2)) = 1, "√2 = 1");
   Check (Floor_Sqrt (U (4)) = 2, "√4 = 2");
   Check (Floor_Sqrt (U (15)) = 3, "√15 = 3");
   Check (Floor_Sqrt (U (100)) = 10, "√100 = 10");
   Check (Floor_Sqrt (U (10_000)) = 100, "√10000 = 100");

   Expect_Invalid_Mul_Mod ("M=0", U (1), U (1), U (0));
   Expect_Invalid_Mod_Exp ("M=0", U (2), U (3), U (0));

   ------------------------------------------------------------------
   Section ("2. Verify_Discrete_Log");
   ------------------------------------------------------------------
   Check (Verify_Discrete_Log (U (2), U (5), U (1019), U (10)),
          "verify 2^10 ≡ 5 (mod 1019)");
   Check (Verify_Discrete_Log (U (5), U (8), U (23), U (6)),
          "verify 5^6 ≡ 8 (mod 23)");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1019), U (11)),
          "reject wrong log");
   Check (not Verify_Discrete_Log (U (2), U (5), U (1), U (10)),
          "reject P<2");
   Check (Verify_Discrete_Log (U (3), U (1), U (17), U (0)),
          "verify 3^0 ≡ 1");

   ------------------------------------------------------------------
   Section ("3. Known small DL instances");
   ------------------------------------------------------------------
   --  2^10 ≡ 5 (mod 1019), interval containing 10
   Check_Instance ("1019/2/5/[0,20]",
                   U (1019), U (2), U (5), U (0), U (20), U (10));
   Check_Instance ("1019/2/5/[5,15]",
                   U (1019), U (2), U (5), U (5), U (15), U (10));
   Check_Instance ("1019/2/5/[10,10] endpoint",
                   U (1019), U (2), U (5), U (10), U (10), U (10));

   --  5^6 ≡ 8 (mod 23)
   Check_Instance ("23/5/8/[0,22]",
                   U (23), U (5), U (8), U (0), U (22), U (6));
   Check_Instance ("23/5/8/[6,6]",
                   U (23), U (5), U (8), U (6), U (6), U (6));
   Check_Instance ("23/5/8/[1,10]",
                   U (23), U (5), U (8), U (1), U (10), U (6));

   --  2^8 ≡ 54 (mod 101)
   Check_Instance ("101/2/54/[0,50]",
                   U (101), U (2), U (54), U (0), U (50), U (8));
   Check_Instance ("101/2/54/[8,8]",
                   U (101), U (2), U (54), U (8), U (8), U (8));

   --  3^4 ≡ 13 (mod 17)  — 3 is generator mod 17, order 16
   Check_Instance ("17/3/13/[0,16]",
                   U (17), U (3), U (13), U (0), U (16), U (4));
   Check_Instance ("17/3/13/[4,4]",
                   U (17), U (3), U (13), U (4), U (4), U (4));

   --  2^5 ≡ 32 (mod 97)
   Check_Instance ("97/2/32/[0,40]",
                   U (97), U (2), U (32), U (0), U (40), U (5));

   --  7^3 ≡ 24 (mod 29) — 7^1=7, 7^2=49≡20, 7^3=140≡24
   Check_Instance ("29/7/24/[0,28]",
                   U (29), U (7), U (24), U (0), U (28), U (3));

   ------------------------------------------------------------------
   Section ("4. Endpoints A and B");
   ------------------------------------------------------------------
   --  Solution at lower endpoint A
   declare
      P : constant U64 := 101;
      G : constant U64 := 2;
      A : constant U64 := 8;
      B : constant U64 := 30;
      Y : constant U64 := Mod_Exp (G, A, P);
   begin
      Check_Instance ("endpoint A=8", P, G, Y, A, B, A);
   end;

   --  Solution at upper endpoint B (tame start)
   declare
      P : constant U64 := 101;
      G : constant U64 := 2;
      A : constant U64 := 0;
      B : constant U64 := 8;
      Y : constant U64 := Mod_Exp (G, B, P);
   begin
      Check_Instance ("endpoint B=8", P, G, Y, A, B, B);
   end;

   declare
      P : constant U64 := 47;
      G : constant U64 := 5;
      A : constant U64 := 0;
      B : constant U64 := 12;
      Y : constant U64 := Mod_Exp (G, B, P);
   begin
      Check_Instance ("endpoint B=12 mod 47", P, G, Y, A, B, B);
   end;

   declare
      P : constant U64 := 47;
      G : constant U64 := 5;
      A : constant U64 := 3;
      B : constant U64 := 20;
      Y : constant U64 := Mod_Exp (G, A, P);
   begin
      Check_Instance ("endpoint A=3 mod 47", P, G, Y, A, B, A);
   end;

   ------------------------------------------------------------------
   Section ("5. Brute-force oracle cross-checks");
   ------------------------------------------------------------------
   Check_Against_Oracle ("oracle 23/5/8/[0,22]",
                         U (23), U (5), U (8), U (0), U (22));
   Check_Against_Oracle ("oracle 101/2/54/[0,50]",
                         U (101), U (2), U (54), U (0), U (50));
   Check_Against_Oracle ("oracle 17/3/13/[0,16]",
                         U (17), U (3), U (13), U (0), U (16));
   Check_Against_Oracle ("oracle 29/7/24/[0,28]",
                         U (29), U (7), U (24), U (0), U (28));
   Check_Against_Oracle ("oracle 97/2/32/[0,40]",
                         U (97), U (2), U (32), U (0), U (40));

   --  No solution in interval: Y = 2^8 but interval is [20,30]
   Check_Against_Oracle ("oracle miss 101/2/54/[20,30]",
                         U (101), U (2), U (54), U (20), U (30));

   ------------------------------------------------------------------
   Section ("6. Bad parameters → Invalid_Argument");
   ------------------------------------------------------------------
   Expect_Invalid_Solve ("P=0", U (0), U (2), U (3), U (0), U (5));
   Expect_Invalid_Solve ("P=1", U (1), U (2), U (3), U (0), U (5));
   Expect_Invalid_Solve ("A>B", U (101), U (2), U (5), U (10), U (5));
   Expect_Invalid_Solve ("G≡0", U (101), U (101), U (5), U (0), U (10));
   Expect_Invalid_Solve ("Y≡0", U (101), U (2), U (202), U (0), U (10));
   Expect_Invalid_Solve ("Max_Steps=0",
                         U (101), U (2), U (5), U (0), U (10), Nat (0));
   Expect_Invalid_Solve ("width too large",
                         U (1_000_003), U (2), U (3),
                         U (0), U (Max_Educational_Width + 1));

   --  Try_Solve also raises on bad params
   declare
      Raised : Boolean := False;
   begin
      begin
         R := Try_Solve_Kangaroo (U (0), U (2), U (3), U (0), U (5));
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument Try_Solve P=0");
   end;

   ------------------------------------------------------------------
   Section ("7. Not_Found / soft miss");
   ------------------------------------------------------------------
   --  Wrong interval: solution is 10, search [50,60]
   Expect_Not_Found ("wrong interval",
                     U (1019), U (2), U (5), U (50), U (60), Nat (5_000));

   R := Try_Solve_Kangaroo
     (U (1019), U (2), U (5), U (50), U (60), Nat (5_000));
   Check (not R.Found, "Try_Solve soft miss wrong interval");

   --  Extremely tiny Max_Steps may fail even on a valid instance
   R := Try_Solve_Kangaroo
     (U (1019), U (2), U (5), U (0), U (100), Nat (1));
   --  With Max_Steps=1: tame may store start only; wild may still hit if
   --  Y equals G^B. Here Y≠G^B so expect miss (or rare hit). Soft check:
   if not R.Found then
      Check (True, "tiny Max_Steps can miss (observed)");
   else
      Check (Verify_Discrete_Log (U (2), U (5), U (1019), R.X),
             "tiny Max_Steps lucky hit still verifies");
   end if;

   ------------------------------------------------------------------
   Section ("8. More generated instances");
   ------------------------------------------------------------------
   declare
      type Triple is record
         P, G, Exp : U64;
      end record;
      Cases : constant array (Positive range <>) of Triple :=
        [(101, 2, 3), (101, 2, 7), (101, 2, 15),
         (47, 5, 1), (47, 5, 9), (47, 5, 11),
         (53, 2, 4), (53, 2, 12), (53, 2, 20),
         (31, 3, 2), (31, 3, 5), (31, 3, 8),
         (61, 10, 3), (61, 10, 7), (61, 10, 14)];
   begin
      for C of Cases loop
         declare
            Y   : constant U64 := Mod_Exp (C.G, C.Exp, C.P);
            Lo  : constant U64 :=
              (if C.Exp >= 2 then C.Exp - 2 else U (0));
            Hi  : constant U64 := C.Exp + 5;
            Lab : constant String :=
              "gen P=" & C.P'Image & " X=" & C.Exp'Image;
         begin
            R := Try_Solve_Kangaroo (C.P, C.G, Y, Lo, Hi);
            Check (R.Found, Lab & " found");
            if R.Found then
               Check (R.X = C.Exp, Lab & " correct");
               Check (Mod_Exp (C.G, R.X, C.P) = Y, Lab & " Mod_Exp");
            else
               Check (False, Lab & " correct");
               Check (False, Lab & " Mod_Exp");
            end if;
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("9. Large-interval kangaroo path (width > 4096)");
   ------------------------------------------------------------------
   --  These force the tame/wild path (not the tiny-interval brute).
   declare
      P : constant U64 := 10007;  -- prime
      G : constant U64 := 5;
      Xs : constant array (Positive range <>) of U64 :=
        [100, 500, 1000, 2500, 4097, 5000, 8000];
   begin
      for Exp of Xs loop
         declare
            Y  : constant U64 := Mod_Exp (G, Exp, P);
            Lo : constant U64 := Exp - 50;
            Hi : constant U64 := Exp + 5000;
            Lab : constant String := "large X=" & Exp'Image;
         begin
            R := Try_Solve_Kangaroo (P, G, Y, Lo, Hi);
            Check (R.Found, Lab & " found");
            if R.Found then
               Check (Verify_Discrete_Log (G, Y, P, R.X), Lab & " verify");
               Check (R.X >= Lo and then R.X <= Hi, Lab & " in range");
            else
               Check (False, Lab & " verify");
               Check (False, Lab & " in range");
            end if;
         end;
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("10. Solve_Kangaroo happy path");
   ------------------------------------------------------------------
   X := Solve_Kangaroo (U (23), U (5), U (8), U (0), U (22));
   Check (X = 6, "Solve_Kangaroo 23 → 6");
   X := Solve_Kangaroo (U (101), U (2), U (54), U (0), U (50));
   Check (X = 8, "Solve_Kangaroo 101 → 8");
   X := Solve_Kangaroo (U (17), U (3), U (13), U (0), U (16));
   Check (X = 4, "Solve_Kangaroo 17 → 4");

   ------------------------------------------------------------------
   --  Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Results: " & Pass_Count'Image & " PASS," & Fail_Count'Image
      & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;
end Tests;
