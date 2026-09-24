--  Standalone test suite for Montgomery_Reduction (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Montgomery_Reduction; use Montgomery_Reduction;

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

   --  Non-static views of package constants (avoid -gnatwc).
   function Max_RB return Natural is (Max_R_Bits);
   function Def_RB return Natural is (Default_R_Bits);

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

begin
   Ada.Text_IO.Put_Line ("Montgomery_Reduction test suite");
   Ada.Text_IO.Put_Line ("===============================");

   ------------------------------------------------------------------
   Section ("1. Helpers: Abs_LI / Mod_Nonneg / Gcd / powers of two");
   ------------------------------------------------------------------
   Check (Abs_LI (5) = 5, "Abs_LI 5");
   Check (Abs_LI (-7) = 7, "Abs_LI -7");
   Check (Mod_Nonneg (5, 3) = 2, "Mod_Nonneg 5 mod 3");
   Check (Mod_Nonneg (-1, 5) = 4, "Mod_Nonneg -1 mod 5");
   Check (Mod_Nonneg (14, 7) = 0, "Mod_Nonneg 14 mod 7");
   Check (Gcd (0, 5) = 5, "Gcd(0,5)");
   Check (Gcd (12, 18) = 6, "Gcd(12,18)");
   Check (Gcd (17, 13) = 1, "Gcd(17,13)");
   Check (Is_Power_Of_Two (1), "2^0=1");
   Check (Is_Power_Of_Two (65536), "2^16");
   Check (not Is_Power_Of_Two (0), "not 0");
   Check (not Is_Power_Of_Two (3), "not 3");
   Check (Floor_Log2 (1) = 0, "log2 1");
   Check (Floor_Log2 (65536) = 16, "log2 65536");
   Check (Max_RB = 30, "Max_R_Bits=30");
   Check (Def_RB = 16, "Default_R_Bits=16");

   ------------------------------------------------------------------
   Section ("2. Classical Mod_Mul / Mod_Pow / Mod_Inverse");
   ------------------------------------------------------------------
   Check (Mod_Mul (7, 15, 17) = 3, "7*15 mod 17 = 3");
   Check (Mod_Mul (-1, 5, 17) = 12, "(-1)*5 mod 17");
   Check (Mod_Pow (3, 5, 7) = 5, "3^5 mod 7 = 5");
   Check (Mod_Pow (2, 10, 1000) = 24, "2^10 mod 1000");
   Check (Mod_Pow (5, 0, 17) = 1, "5^0 mod 17 = 1");
   Check (Mod_Inverse (3, 7) = 5, "3^{-1} mod 7 = 5");
   Check (Mod_Inverse (15, 34) = 25, "15^{-1} mod 34 = 25");
   Check (Mod_Mul (3, Mod_Inverse (3, 7), 7) = 1, "3*inv ≡ 1 mod 7");
   declare
      procedure Bad_Inv is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Mod_Inverse (2, 4);
      end Bad_Inv;
      procedure Bad_Pow is
         X : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Mod_Pow (2, -1, 17);
      end Bad_Pow;
   begin
      Check (Raised_Invalid (Bad_Inv'Access), "Mod_Inverse non-coprime");
      Check (Raised_Invalid (Bad_Pow'Access), "Mod_Pow negative exp");
   end;

   ------------------------------------------------------------------
   Section ("3. Create_Context / N' / invalid params");
   ------------------------------------------------------------------
   declare
      Ctx : Context;
   begin
      Ctx := Create_Context (17, 5);  -- R=32
      Check (Ctx.N = 17, "N=17");
      Check (Ctx.R = 32, "R=32");
      Check (Ctx.R_Bits = 5, "R_Bits=5");
      Check (Is_Valid_Context (Ctx), "valid ctx N=17 R=32");
      Check (Mod_Nonneg (Ctx.N * Ctx.N_Prime, Ctx.R) = Ctx.R - 1,
             "N*N' ≡ -1 mod R (17,32)");
      Check (Ctx.N_Prime = 15, "N'=15 for N=17 R=32");
      Check (Ctx.R_Mod_N = 32 rem 17, "R_Mod_N");
      Check (Ctx.R2_Mod_N = Mod_Mul (Ctx.R_Mod_N, Ctx.R_Mod_N, 17),
             "R2_Mod_N");

      Ctx := Create_Context (17);  -- default R_Bits=16
      Check (Ctx.R = 65536, "default R=2^16");
      Check (Is_Valid_Context (Ctx), "valid default ctx");
      Check (Mod_Nonneg (Ctx.N * Ctx.N_Prime, Ctx.R) = Ctx.R - 1,
             "N*N' ≡ -1 default");

      Ctx := Create_Context (97, 8);
      Check (Is_Valid_Context (Ctx), "valid N=97 R=256");
      Check (Mod_Nonneg (Ctx.N * Ctx.N_Prime, Ctx.R) = Ctx.R - 1,
             "N*N' ≡ -1 (97,256)");

      Ctx := Create_Context (65535, 16);  -- N = R-1
      Check (Is_Valid_Context (Ctx), "valid N=65535 R=65536");
   end;

   declare
      procedure Even_N is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (16, 8);
      end Even_N;
      procedure Tiny_N is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (1, 8);
      end Tiny_N;
      procedure Zero_N is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (0, 8);
      end Zero_N;
      procedure R_Too_Small is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (100, 6);  -- R=64 < 100
      end R_Too_Small;
      procedure R_Bits_Zero is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (17, 0);
      end R_Bits_Zero;
      procedure R_Bits_Huge is
         C : Context;
         pragma Unreferenced (C);
      begin
         C := Create_Context (17, Max_R_Bits + 1);
      end R_Bits_Huge;
   begin
      Check (Raised_Invalid (Even_N'Access), "reject even N");
      Check (Raised_Invalid (Tiny_N'Access), "reject N=1");
      Check (Raised_Invalid (Zero_N'Access), "reject N=0");
      Check (Raised_Invalid (R_Too_Small'Access), "reject R<=N");
      Check (Raised_Invalid (R_Bits_Zero'Access), "reject R_Bits=0");
      Check (Raised_Invalid (R_Bits_Huge'Access), "reject R_Bits>Max");
   end;

   ------------------------------------------------------------------
   Section ("4. To/From Montgomery roundtrip");
   ------------------------------------------------------------------
   declare
      Ctx : constant Context := Create_Context (17, 5);
      Samples : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 7, 15, 16];
      Tilde, Back : Long_Integer;
   begin
      for A of Samples loop
         Tilde := To_Montgomery (Ctx, A);
         Back := From_Montgomery (Ctx, Tilde);
         Check (Back = A, "roundtrip a=" & A'Image);
      end loop;
      Check (To_Montgomery (Ctx, 7) = Mod_Mul (7, Ctx.R_Mod_N, Ctx.N),
             "tilde = a*R mod N for 7");
      Check (From_Montgomery (Ctx, To_Montgomery (Ctx, -1)) = 16,
             "roundtrip -1");
      Check (From_Montgomery (Ctx, To_Montgomery (Ctx, 17)) = 0,
             "roundtrip 17");
      Check (From_Montgomery (Ctx, To_Montgomery (Ctx, 100)) =
               Mod_Nonneg (100, 17),
             "roundtrip 100");
   end;

   declare
      Ctx : constant Context := Create_Context (97, 10);
      Samples : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 5, 10, 50, 96];
   begin
      for A of Samples loop
         Check
           (From_Montgomery (Ctx, To_Montgomery (Ctx, A)) = A,
            "roundtrip97 a=" & A'Image);
      end loop;
      Check (To_Montgomery (Ctx, 1) = Ctx.R_Mod_N, "Mont(1)=R mod N");
      Check (From_Montgomery (Ctx, Ctx.R_Mod_N) = 1, "From(R mod N)=1");
      Check (From_Montgomery (Ctx, 0) = 0, "From(0)=0");
   end;

   ------------------------------------------------------------------
   Section ("5. REDC properties (Wikipedia-style)");
   ------------------------------------------------------------------
   declare
      --  N=17, R=32, N'=15 (computed). Product of Mont(7)*Mont(15)=3*4=12.
      Ctx : constant Context := Create_Context (17, 5);
      M7  : constant Long_Integer := To_Montgomery (Ctx, 7);
      M15 : constant Long_Integer := To_Montgomery (Ctx, 15);
      T   : constant Long_Integer := M7 * M15;
      S   : constant Long_Integer := REDC (Ctx, T);
   begin
      Check (M7 = 3, "Mont(7)=3 for R=32");
      Check (M15 = 4, "Mont(15)=4 for R=32");
      Check (T = 12, "product of Mont forms = 12");
      Check (S = 11, "REDC(12)=11 = Mont(3)");
      Check (From_Montgomery (Ctx, S) = 3, "From REDC = 7*15 mod 17");
      Check (REDC (Ctx, 0) = 0, "REDC(0)=0");
      Check (REDC (Ctx, Ctx.R_Mod_N) = 1, "REDC(R mod N)=1");
      --  REDC(a) ≡ a * R^{-1} mod N
      declare
         R_Inv : constant Long_Integer := Mod_Inverse (Ctx.R_Mod_N, Ctx.N);
      begin
         Check
           (REDC (Ctx, 5) = Mod_Mul (5, R_Inv, Ctx.N),
            "REDC(5) ≡ 5 R^{-1} mod N");
         Check
           (REDC (Ctx, 20) = Mod_Mul (20, R_Inv, Ctx.N),
            "REDC(20) ≡ 20 R^{-1} mod N");
      end;
   end;

   declare
      procedure Neg_T is
         Ctx : constant Context := Create_Context (17, 5);
         X   : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := REDC (Ctx, -1);
      end Neg_T;
   begin
      Check (Raised_Invalid (Neg_T'Access), "REDC rejects T<0");
   end;

   ------------------------------------------------------------------
   Section ("6. Montgomery_Multiply ≡ classical Mod_Mul");
   ------------------------------------------------------------------
   declare
      Ctx : constant Context := Create_Context (17, 5);
      As : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 7, 16];
      Bs : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 5, 15];
      A_T, B_T, P_T, P : Long_Integer;
   begin
      for A of As loop
         for B of Bs loop
            A_T := To_Montgomery (Ctx, A);
            B_T := To_Montgomery (Ctx, B);
            P_T := Montgomery_Multiply (Ctx, A_T, B_T);
            P := From_Montgomery (Ctx, P_T);
            Check
              (P = Mod_Mul (A, B, 17),
               "mont mul " & A'Image & "*" & B'Image);
         end loop;
      end loop;
   end;

   declare
      Ctx : constant Context := Create_Context (97, 8);
      Pairs : constant array (1 .. 5, 1 .. 2) of Long_Integer :=
        [[1, 1], [10, 20], [96, 96], [0, 5], [41, 53]];
      A, B, P : Long_Integer;
   begin
      for I in Pairs'Range (1) loop
         A := Pairs (I, 1);
         B := Pairs (I, 2);
         P := From_Montgomery
           (Ctx,
            Montgomery_Multiply
              (Ctx, To_Montgomery (Ctx, A), To_Montgomery (Ctx, B)));
         Check (P = Mod_Mul (A, B, 97),
                "mont mul97 " & A'Image & "*" & B'Image);
      end loop;
   end;

   ------------------------------------------------------------------
   Section ("7. Montgomery_Pow ≡ classical Mod_Pow");
   ------------------------------------------------------------------
   declare
      Ctx : constant Context := Create_Context (17, 5);
      Bases : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 7, 16];
      Exps  : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 5, 10];
   begin
      for Base of Bases loop
         for Exp of Exps loop
            Check
              (Montgomery_Pow (Ctx, Base, Exp) = Mod_Pow (Base, Exp, 17),
               "pow " & Base'Image & "^" & Exp'Image);
         end loop;
      end loop;
   end;

   declare
      Ctx : constant Context := Create_Context (97, 10);
      Cases : constant array (1 .. 6, 1 .. 2) of Long_Integer :=
        [[2, 0], [2, 10], [3, 5], [96, 3], [0, 5], [50, 50]];
   begin
      for I in Cases'Range (1) loop
         Check
           (Montgomery_Pow (Ctx, Cases (I, 1), Cases (I, 2)) =
              Mod_Pow (Cases (I, 1), Cases (I, 2), 97),
            "pow97 " & Cases (I, 1)'Image & "^" & Cases (I, 2)'Image);
      end loop;
   end;

   declare
      procedure Neg_Exp is
         Ctx : constant Context := Create_Context (17, 5);
         X   : Long_Integer;
         pragma Unreferenced (X);
      begin
         X := Montgomery_Pow (Ctx, 2, -1);
      end Neg_Exp;
   begin
      Check (Raised_Invalid (Neg_Exp'Access), "Montgomery_Pow Exp<0");
   end;

   ------------------------------------------------------------------
   Section ("8. Larger odd moduli / default R");
   ------------------------------------------------------------------
   declare
      Ctx : constant Context := Create_Context (10007);  -- prime, R=2^16
      A, B, P : Long_Integer;
   begin
      Check (Is_Valid_Context (Ctx), "ctx N=10007");
      Check (Ctx.R = 65536, "R=65536");
      A := 1234;
      B := 5678;
      P := From_Montgomery
        (Ctx,
         Montgomery_Multiply
           (Ctx, To_Montgomery (Ctx, A), To_Montgomery (Ctx, B)));
      Check (P = Mod_Mul (A, B, 10007), "mont mul 10007");
      Check
        (Montgomery_Pow (Ctx, 3, 100) = Mod_Pow (3, 100, 10007),
         "pow 3^100 mod 10007");
      Check
        (From_Montgomery (Ctx, To_Montgomery (Ctx, 9999)) = 9999,
         "roundtrip 9999");
   end;

   declare
      Ctx : constant Context := Create_Context (65521, 16);  -- prime < 2^16
   begin
      Check (Is_Valid_Context (Ctx), "ctx N=65521");
      Check
        (Montgomery_Pow (Ctx, 7, 13) = Mod_Pow (7, 13, 65521),
         "pow 7^13 mod 65521");
      Check
        (From_Montgomery
           (Ctx,
            Montgomery_Multiply
              (Ctx,
               To_Montgomery (Ctx, 11111),
               To_Montgomery (Ctx, 22222))) =
           Mod_Mul (11111, 22222, 65521),
         "mont mul 65521");
   end;

   ------------------------------------------------------------------
   Section ("9. Identity / zero / associativity sketches");
   ------------------------------------------------------------------
   declare
      Ctx : constant Context := Create_Context (19, 6);
      Samples : constant array (Positive range <>) of Long_Integer :=
        [0, 1, 9, 18];
      A_T, One_T, Z_T, P_T : Long_Integer;
   begin
      One_T := Ctx.R_Mod_N;
      Z_T := To_Montgomery (Ctx, 0);
      Check (From_Montgomery (Ctx, Z_T) = 0, "Mont(0)=0 path");
      for A of Samples loop
         A_T := To_Montgomery (Ctx, A);
         P_T := Montgomery_Multiply (Ctx, A_T, One_T);
         Check (From_Montgomery (Ctx, P_T) = A,
                "a*1 mont a=" & A'Image);
         P_T := Montgomery_Multiply (Ctx, A_T, Z_T);
         Check (From_Montgomery (Ctx, P_T) = 0,
                "a*0 mont a=" & A'Image);
      end loop;
      --  (2*3)*5 = 2*(3*5) in Montgomery domain
      declare
         T2 : constant Long_Integer := To_Montgomery (Ctx, 2);
         T3 : constant Long_Integer := To_Montgomery (Ctx, 3);
         T5 : constant Long_Integer := To_Montgomery (Ctx, 5);
         L  : constant Long_Integer :=
           Montgomery_Multiply
             (Ctx, Montgomery_Multiply (Ctx, T2, T3), T5);
         R  : constant Long_Integer :=
           Montgomery_Multiply
             (Ctx, T2, Montgomery_Multiply (Ctx, T3, T5));
      begin
         Check (From_Montgomery (Ctx, L) = From_Montgomery (Ctx, R),
                "assoc (2*3)*5");
         Check (From_Montgomery (Ctx, L) = Mod_Mul (Mod_Mul (2, 3, 19), 5, 19),
                "assoc value 30 mod 19");
      end;
   end;

   ------------------------------------------------------------------
   Section ("10. Is_Valid_Context rejects tampered records");
   ------------------------------------------------------------------
   declare
      Ctx : Context := Create_Context (17, 5);
   begin
      Check (Is_Valid_Context (Ctx), "fresh valid");
      Ctx.N_Prime := Ctx.N_Prime + 1;
      Check (not Is_Valid_Context (Ctx), "bad N_Prime");
      Ctx := Create_Context (17, 5);
      Ctx.R2_Mod_N := 0;
      Check (not Is_Valid_Context (Ctx), "bad R2");
      Ctx := Create_Context (17, 5);
      Ctx.N := 18;
      Check (not Is_Valid_Context (Ctx), "even N tamper");
      Ctx := Context'(others => <>);
      Check (not Is_Valid_Context (Ctx), "default record invalid");
   end;

   ------------------------------------------------------------------
   -- Summary
   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("===============================");
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
