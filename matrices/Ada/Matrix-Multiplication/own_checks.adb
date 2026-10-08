--  Own checks (see tests/SOURCES.txt). Assume Matrix_Multiplication is wrong
--  or does nothing; compare it with references that use a different method:
--  * products: outer-product (k-outer) accumulation, on integer-valued
--    matrices so Float sums are exact and results are compared with "=";
--    every N in 1 .. 12 and 16, offset index ranges, all Strassen leaves,
--    every Cannon grid P with N mod P = 0 (and every invalid grid);
--  * scalar-multiply counts and depths from the closed forms N**3 and
--    7**d * (P / 2**d)**3;
--  * Freivalds: a separate LCG on Unsigned_64 (constants from the spec
--    comment / README) and brute-force A (B r) vs C r;
--  * helpers: bit tests, exhaustive small ranges, element-wise definitions;
--  * taxonomy: the README method and milestone tables.
pragma Ada_2022;
with Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Interfaces; use Interfaces;
with Matrix_Multiplication; use Matrix_Multiplication;

procedure Own_Checks is
   Failures : Natural := 0;
   Checked  : Natural := 0;

   procedure Expect (Cond : Boolean; What : String) is
   begin
      Checked := Checked + 1;
      if not Cond then
         Failures := Failures + 1;
         if Failures <= 25 then
            Ada.Text_IO.Put_Line ("  FAIL own: " & What);
         end if;
      end if;
   end Expect;

   --  xorshift32 for test data (not the package's LCG)
   X : Unsigned_32 := 2463534242;
   function Next_Int (Lo, Hi : Integer) return Integer is
   begin
      X := X xor Shift_Left (X, 13);
      X := X xor Shift_Right (X, 17);
      X := X xor Shift_Left (X, 5);
      return Lo + Integer (X mod Unsigned_32 (Hi - Lo + 1));
   end Next_Int;

   function Rand_Mat (N : Natural; R0, C0 : Positive) return Matrix is
      M : Matrix (R0 .. R0 + N - 1, C0 .. C0 + N - 1);
   begin
      for I in M'Range (1) loop
         for J in M'Range (2) loop
            M (I, J) := Float (Next_Int (-5, 5));
         end loop;
      end loop;
      return M;
   end Rand_Mat;

   function Rand_Int_Mat (N : Natural; R0, C0 : Positive; Lo, Hi : Integer) return Int_Matrix is
      M : Int_Matrix (R0 .. R0 + N - 1, C0 .. C0 + N - 1);
   begin
      for I in M'Range (1) loop
         for J in M'Range (2) loop
            M (I, J) := Next_Int (Lo, Hi);
         end loop;
      end loop;
      return M;
   end Rand_Int_Mat;

   --  reference: C := sum over K of column K of A times row K of B
   function Ref_Product (A, B : Matrix) return Matrix is
      N : constant Natural := A'Length (1);
      C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for K in 0 .. N - 1 loop
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               C (I + 1, J + 1) := C (I + 1, J + 1)
                 + A (A'First (1) + I, A'First (2) + K) * B (B'First (1) + K, B'First (2) + J);
            end loop;
         end loop;
      end loop;
      return C;
   end Ref_Product;

   function Same_Product (R : Multiply_Result; C : Matrix) return Boolean is
   begin
      if not R.Success or else R.Stat /= Ok or else R.N /= C'Length (1) then
         return False;
      end if;
      for I in C'Range (1) loop
         for J in C'Range (2) loop
            if R.C (I, J) /= C (I, J) then
               return False;
            end if;
         end loop;
      end loop;
      declare
         P : constant Matrix := Product_Matrix (R);
      begin
         if P'Length (1) /= C'Length (1) or else P'Length (2) /= C'Length (2) then
            return False;
         end if;
         for I in C'Range (1) loop
            for J in C'Range (2) loop
               if P (I, J) /= C (I, J) then
                  return False;
               end if;
            end loop;
         end loop;
      end;
      return True;
   end Same_Product;

   function Pow2_Ceil (N : Positive) return Positive is
   begin
      for K in 0 .. 6 loop
         if 2 ** K >= N then
            return 2 ** K;
         end if;
      end loop;
      return 128;
   end Pow2_Ceil;

   --  reference LCG (spec: multiplier 1103515245, increment 12345, modulus
   --  2**31; README: bit 16 of the new state)
   procedure Ref_LCG (S : in out Unsigned_64) is
   begin
      S := (1_103_515_245 * S + 12_345) and (2 ** 31 - 1);
   end Ref_LCG;

   function Ref_Bit (S : in out Unsigned_64) return Integer is
   begin
      Ref_LCG (S);
      return Integer (Shift_Right (S, 16) and 1);
   end Ref_Bit;

   --  brute force: does (A B - C) r = 0 for the reference r?
   function Ref_Once (A, B, C : Int_Matrix; S : in out Unsigned_64) return Verdict is
      N  : constant Natural := A'Length (1);
      Rv : array (0 .. N - 1) of Long_Long_Integer;
   begin
      for I in Rv'Range loop
         Rv (I) := Long_Long_Integer (Ref_Bit (S));
      end loop;
      for I in 0 .. N - 1 loop
         declare
            L, Rr : Long_Long_Integer := 0;
         begin
            for K in 0 .. N - 1 loop
               declare
                  BK : Long_Long_Integer := 0;
               begin
                  for J in 0 .. N - 1 loop
                     BK := BK + Long_Long_Integer (B (B'First (1) + K, B'First (2) + J)) * Rv (J);
                  end loop;
                  L := L + Long_Long_Integer (A (A'First (1) + I, A'First (2) + K)) * BK;
               end;
               Rr := Rr + Long_Long_Integer (C (C'First (1) + I, C'First (2) + K)) * Rv (K);
            end loop;
            if L /= Rr then
               return Unequal;
            end if;
         end;
      end loop;
      return Equal_Probably;
   end Ref_Once;

   function Ref_Int_Product (A, B : Int_Matrix) return Int_Matrix is
      N : constant Natural := A'Length (1);
      C : Int_Matrix (1 .. N, 1 .. N) := [others => [others => 0]];
   begin
      for K in 0 .. N - 1 loop
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               C (I + 1, J + 1) := C (I + 1, J + 1)
                 + A (A'First (1) + I, A'First (2) + K) * B (B'First (1) + K, B'First (2) + J);
            end loop;
         end loop;
      end loop;
      return C;
   end Ref_Int_Product;

   Sizes : constant array (Positive range <>) of Positive := [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 16];
begin
   ---------------------------------------------------------------- products
   for N of Sizes loop
      for Rep in 1 .. 2 loop
         declare
            R0 : constant Positive := (if Rep = 1 then 1 else 3);
            A  : constant Matrix := Rand_Mat (N, R0, R0 + 4);
            B  : constant Matrix := Rand_Mat (N, R0 + 2, R0 + 1);
            C  : constant Matrix := Ref_Product (A, B);
            Rc : constant Multiply_Result := Multiply_Classical (A, B);
            Rd : constant Multiply_Result := Multiply (A, B, Classical);
            P  : constant Positive := Pow2_Ceil (N);
         begin
            Expect (Same_Product (Rc, C), "Classical N=" & N'Image);
            Expect (Same_Product (Rd, C), "Multiply Classical N=" & N'Image);
            Expect (Rc.Scalar_Multiplies = N ** 3 and then Rc.Recursion_Depth = 0
                    and then Rc.Padded_N = 0 and then Rc.Method = Method_Kind'Pos (Classical),
                    "Classical metadata N=" & N'Image);
            for Leaf in 1 .. 17 loop
               declare
                  Rs : constant Multiply_Result := Multiply_Strassen (A, B, Leaf);
                  Rm : constant Multiply_Result := Multiply (A, B, Strassen, Leaf => Leaf);
                  D  : Natural := 0;
               begin
                  while P / 2 ** D > Leaf and then P / 2 ** D > 1 loop
                     D := D + 1;
                  end loop;
                  Expect (Same_Product (Rs, C), "Strassen N=" & N'Image & " leaf" & Leaf'Image);
                  Expect (Same_Product (Rm, C), "Multiply Strassen N=" & N'Image & " leaf" & Leaf'Image);
                  Expect (Rs.Padded_N = P and then Rs.Recursion_Depth = D
                          and then Rs.Scalar_Multiplies = 7 ** D * (P / 2 ** D) ** 3
                          and then Rs.Method = Method_Kind'Pos (Strassen),
                          "Strassen metadata N=" & N'Image & " leaf" & Leaf'Image
                          & " got P" & Rs.Padded_N'Image & " d" & Rs.Recursion_Depth'Image
                          & " m" & Rs.Scalar_Multiplies'Image);
               end;
            end loop;
            for G in 0 .. N + 2 loop
               declare
                  Rn : constant Multiply_Result := Multiply_Cannon (A, B, G);
                  Rm : constant Multiply_Result := Multiply (A, B, Cannon, Grid_P => G);
                  PP : constant Natural := (if G = 0 then N else G);
               begin
                  if PP <= N and then N mod PP = 0 then
                     Expect (Same_Product (Rn, C), "Cannon N=" & N'Image & " P" & G'Image);
                     Expect (Same_Product (Rm, C), "Multiply Cannon N=" & N'Image & " P" & G'Image);
                     Expect (Rn.Grid_P = PP and then Rn.Block_Size = N / PP and then Rn.Shift_Count = PP
                             and then Rn.Method = Method_Kind'Pos (Cannon),
                             "Cannon metadata N=" & N'Image & " P" & G'Image);
                  else
                     Expect (not Rn.Success and then Rn.Stat = Dimension_Error
                             and then Rn.Grid_P = PP and then Rn.N = N
                             and then Rn.Method = Method_Kind'Pos (Cannon),
                             "Cannon invalid grid N=" & N'Image & " P" & G'Image);
                  end if;
               end;
            end loop;
         end;
      end loop;
   end loop;
   --  dimension errors (0 x 0 and 33 x 33 are square, so allowed by Pre)
   declare
      E  : constant Matrix (1 .. 0, 1 .. 0) := [others => [others => 0.0]];
      Bg : constant Matrix (1 .. Max_N + 1, 1 .. Max_N + 1) := [others => [others => 1.0]];
   begin
      Expect (not Multiply_Classical (E, E).Success and then Multiply_Classical (E, E).Stat = Dimension_Error,
              "Classical 0x0 rejected");
      Expect (not Multiply_Strassen (E, E).Success and then Multiply_Strassen (E, E).Stat = Dimension_Error,
              "Strassen 0x0 rejected");
      Expect (not Multiply_Cannon (E, E).Success and then Multiply_Cannon (E, E).Stat = Dimension_Error,
              "Cannon 0x0 rejected");
      Expect (not Multiply_Classical (Bg, Bg).Success and then Multiply_Classical (Bg, Bg).Stat = Dimension_Error
              and then Multiply_Classical (Bg, Bg).Method = Method_Kind'Pos (Classical),
              "Classical 33x33 rejected");
      Expect (not Multiply_Strassen (Bg, Bg).Success and then Multiply_Strassen (Bg, Bg).Stat = Dimension_Error
              and then Multiply_Strassen (Bg, Bg).Method = Method_Kind'Pos (Strassen),
              "Strassen 33x33 rejected");
      Expect (not Multiply_Cannon (Bg, Bg).Success and then Multiply_Cannon (Bg, Bg).Stat = Dimension_Error,
              "Cannon 33x33 rejected");
      declare
         A32 : constant Matrix := Rand_Mat (Max_N, 1, 1);
         B32 : constant Matrix := Rand_Mat (Max_N, 1, 1);
         C32 : constant Matrix := Ref_Product (A32, B32);
      begin
         Expect (Same_Product (Multiply_Classical (A32, B32), C32), "Classical N=32");
         Expect (Same_Product (Multiply_Strassen (A32, B32, 4), C32), "Strassen N=32");
         Expect (Same_Product (Multiply_Cannon (A32, B32, 8), C32), "Cannon N=32 P=8");
      end;
      declare
         A2 : constant Matrix := Rand_Mat (3, 1, 1);
      begin
         for M in Method_Kind loop
            declare
               R : constant Multiply_Result := Multiply (A2, A2, M);
            begin
               case M is
                  when Classical | Strassen | Cannon =>
                     Expect (Same_Product (R, Ref_Product (A2, A2)), "dispatch runs " & M'Image);
                  when Laser_Family =>
                     Expect (not R.Success and then R.Stat = Galactic_Only
                             and then R.Method = Method_Kind'Pos (M), "Laser catalogue reject");
                  when others =>
                     Expect (not R.Success and then R.Stat = Not_Implemented
                             and then R.Method = Method_Kind'Pos (M), "catalogue reject " & M'Image);
               end case;
            end;
         end loop;
      end;
   end;
   ---------------------------------------------------------------- integer
   for N in 1 .. 10 loop
      declare
         A  : constant Int_Matrix := Rand_Int_Mat (N, 2, 5, -50, 50);
         B  : constant Int_Matrix := Rand_Int_Mat (N, 4, 1, -50, 50);
         C  : constant Int_Matrix := Ref_Int_Product (A, B);
         R  : constant Int_Multiply_Result := Multiply_Classical_Int (A, B);
         Ok : Boolean := R.Success and then R.N = N;
      begin
         if Ok then
            declare
               P : constant Int_Matrix := Int_Product_Matrix (R);
            begin
               Ok := P'Length (1) = N and then P'Length (2) = N;
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     Ok := Ok and then P (I, J) = C (I, J) and then R.C (I, J) = C (I, J);
                  end loop;
               end loop;
            end;
         end if;
         Expect (Ok, "Multiply_Classical_Int N=" & N'Image);
         Expect (Int_Mat_Equal (Int_Product_Matrix (R), C), "Int_Mat_Equal on equal product N=" & N'Image);
         --  Int_Mat_Vec against brute force
         declare
            Xv : Int_Vector (3 .. N + 2);
            Y  : Int_Vector (A'Range (1));
            Good : Boolean := True;
         begin
            for I in Xv'Range loop
               Xv (I) := Next_Int (-9, 9);
            end loop;
            Y := Int_Mat_Vec (A, Xv);
            for I in A'Range (1) loop
               declare
                  S : Integer := 0;
               begin
                  for K in 0 .. N - 1 loop
                     S := S + A (I, A'First (2) + K) * Xv (Xv'First + K);
                  end loop;
                  Good := Good and then Y (I) = S;
               end;
            end loop;
            Expect (Good, "Int_Mat_Vec N=" & N'Image);
         end;
         --  Freivalds against the reference
         for Case_No in 1 .. 40 loop
            declare
               CC : Int_Matrix := C;
               Seed : constant Natural := Next_Int (0, 1_000_000);
               S1 : Natural := Seed;
               S2 : Unsigned_64 := Unsigned_64 (Seed);
               Trials : constant Positive := Next_Int (1, 12);
               V  : Verdict;
               VR : Verify_Result;
               Used, Fails : Natural := 0;
               Stat : Verdict := Equal_Probably;
               S3 : Unsigned_64 := Unsigned_64 (Seed);
            begin
               if Case_No mod 2 = 0 then
                  declare
                     I : constant Positive := Next_Int (1, N);
                     J : constant Positive := Next_Int (1, N);
                     Off : constant Integer := Next_Int (1, 3) * (if Case_No mod 4 = 0 then -1 else 1);
                     CR : constant Int_Matrix := Corrupt_Entry (CC, I, J, Off);
                     Same_Else : Boolean := CR (I, J) = CC (I, J) + Off;
                  begin
                     for P in 1 .. N loop
                        for Q in 1 .. N loop
                           if P /= I or else Q /= J then
                              Same_Else := Same_Else and then CR (P, Q) = CC (P, Q);
                           end if;
                        end loop;
                     end loop;
                     Expect (Same_Else, "Corrupt_Entry changes exactly one entry by Offset");
                     Expect (not Int_Mat_Equal (CR, CC), "Int_Mat_Equal sees a corrupted entry");
                     CC := CR;
                  end;
               end if;
               V := Verify_Freivalds_Once (A, B, CC, S1);
               Expect (V = Ref_Once (A, B, CC, S2), "Verify_Freivalds_Once verdict N=" & N'Image);
               Expect (Unsigned_64 (S1) = S2, "Verify_Freivalds_Once seed advance N=" & N'Image);
               VR := Verify_Freivalds (A, B, CC, Trials, Seed);
               for T in 1 .. Trials loop
                  Used := Used + 1;
                  if Ref_Once (A, B, CC, S3) = Unequal then
                     Fails := 1;
                     Stat := Unequal;
                     exit;
                  end if;
               end loop;
               Expect (VR.Stat = Stat and then VR.Trials_Used = Used and then VR.Failures = Fails
                       and then VR.N = N and then Unsigned_64 (VR.Seed_Final) = S3,
                       "Verify_Freivalds N=" & N'Image & " case" & Case_No'Image);
               if Case_No mod 2 = 1 then
                  Expect (VR.Stat = Equal_Probably, "Freivalds accepts the true product");
               end if;
            end;
         end loop;
      end;
   end loop;
   --  Freivalds dimension errors
   declare
      A3 : constant Int_Matrix := Int_Identity (3);
      C2 : constant Int_Matrix := Int_Identity (2);
      E  : constant Int_Matrix (1 .. 0, 1 .. 0) := [others => [others => 0]];
      S  : Natural := 5;
      VR : Verify_Result;
   begin
      Expect (Verify_Freivalds_Once (E, E, E, S) = Dimension_Error and then S = 5, "Once 0x0");
      --  size mismatches are excluded by the preconditions (checked with -gnata)
      Expect (Int_Mat_Equal (A3, A3) and then not Int_Mat_Equal (C2, Int_Zeros (2)), "Int_Mat_Equal identity");
      VR := Verify_Freivalds (E, E, E, 4, 9);
      Expect (VR.Stat = Dimension_Error and then VR.Trials_Used = 0 and then VR.N = 0
              and then VR.Failures = 0 and then VR.Seed_Final = 9, "Verify 0x0");
      Expect (not Multiply_Classical_Int (E, E).Success and then Multiply_Classical_Int (E, E).N = 0, "Int 0x0");
      --  Max_N itself is accepted by every Integer path
      declare
         A32 : constant Int_Matrix := Rand_Int_Mat (Max_N, 1, 1, -3, 3);
         B32 : constant Int_Matrix := Rand_Int_Mat (Max_N, 1, 1, -3, 3);
         C32 : constant Int_Matrix := Ref_Int_Product (A32, B32);
         S32 : Natural := 11;
      begin
         Expect (Verify_Freivalds_Once (A32, B32, C32, S32) = Equal_Probably, "Once N=32 accepts the product");
         VR := Verify_Freivalds (A32, B32, C32, 3, 11);
         Expect (VR.Stat = Equal_Probably and then VR.N = Max_N and then VR.Trials_Used = 3, "Verify N=32");
      end;
      --  Int_Mat_Equal with different index origins, a difference at every position
      declare
         A : constant Int_Matrix := Rand_Int_Mat (3, 4, 2, -9, 9);
         B : Int_Matrix (7 .. 9, 1 .. 3);
      begin
         for I in 0 .. 2 loop
            for J in 0 .. 2 loop
               B (7 + I, 1 + J) := A (4 + I, 2 + J);
            end loop;
         end loop;
         Expect (Int_Mat_Equal (A, B) and then Int_Mat_Equal (A => B, B => A), "Int_Mat_Equal offset origins");
         for I in 0 .. 2 loop
            for J in 0 .. 2 loop
               declare
                  C : Int_Matrix := B;
               begin
                  C (7 + I, 1 + J) := C (7 + I, 1 + J) + 1;
                  Expect (not Int_Mat_Equal (A, C) and then not Int_Mat_Equal (C, A),
                          "Int_Mat_Equal offset origins, difference at" & I'Image & J'Image);
               end;
            end loop;
         end loop;
      end;
   end;
   ---------------------------------------------------------------- LCG
   for Seed in 0 .. 3000 loop
      declare
         S1 : Natural := Seed * 7919;
         S2 : Unsigned_64 := Unsigned_64 (Seed * 7919);
         S3 : Natural := Seed * 7919;
         S4 : Unsigned_64 := Unsigned_64 (Seed * 7919);
         B1 : Integer;
      begin
         LCG_Next (S1);
         Ref_LCG (S2);
         Expect (Unsigned_64 (S1) = S2, "LCG_Next seed" & Seed'Image);
         B1 := LCG_Bit (S3);
         Expect (B1 = Ref_Bit (S4) and then Unsigned_64 (S3) = S4, "LCG_Bit seed" & Seed'Image);
      end;
   end loop;
   declare
      S1 : Natural := 42;
      S2 : Unsigned_64 := 42;
      V  : constant Int_Vector := Random_01_Vector (20, S1);
      Good : Boolean := V'First = 1 and then V'Last = 20;
   begin
      for I in V'Range loop
         Good := Good and then V (I) = Ref_Bit (S2);
      end loop;
      Expect (Good and then Unsigned_64 (S1) = S2, "Random_01_Vector");
   end;
   ---------------------------------------------------------------- helpers
   for N in 0 .. 5000 loop
      Expect (Is_Power_Of_Two (N) = (N > 0 and then (Unsigned_32 (N) and Unsigned_32 (N - (if N > 0 then 1 else 0))) = 0),
              "Is_Power_Of_Two" & N'Image);
   end loop;
   Expect (Next_Power_Of_Two (0) = 0, "Next_Power_Of_Two 0");
   for N in 1 .. Max_N loop
      Expect (Next_Power_Of_Two (N) = Pow2_Ceil (N), "Next_Power_Of_Two" & N'Image);
   end loop;
   for P in 0 .. 40 loop
      for N in 0 .. 40 loop
         declare
            Div : Boolean := False;
         begin
            for Q in 0 .. N loop
               Div := Div or else (P > 0 and then Q * P = N);
            end loop;
            Expect (Divides (P, N) = Div, "Divides" & P'Image & N'Image);
            Expect (Is_Valid_Grid (N, P) = (Div and then P >= 1 and then P <= N and then N <= Max_N),
                    "Is_Valid_Grid" & N'Image & P'Image);
         end;
      end loop;
   end loop;
   declare
      A : constant Matrix := Rand_Mat (4, 2, 6);
      B : constant Matrix := Rand_Mat (4, 7, 1);
      S : constant Matrix := Mat_Add (A, B);
      D : constant Matrix := Mat_Sub (A, B);
      K : constant Matrix := Mat_Scale (A, -3.0);
      Good : Boolean := S'First (1) = 2 and then S'First (2) = 6 and then D'First (1) = 2
        and then K'First (2) = 6 and then S'Length (1) = 4 and then D'Length (2) = 4;
      Sq, Dq : Float := 0.0;
   begin
      for I in 0 .. 3 loop
         for J in 0 .. 3 loop
            Good := Good and then S (2 + I, 6 + J) = A (2 + I, 6 + J) + B (7 + I, 1 + J)
              and then D (2 + I, 6 + J) = A (2 + I, 6 + J) - B (7 + I, 1 + J)
              and then K (2 + I, 6 + J) = -3.0 * A (2 + I, 6 + J);
            Sq := Sq + A (2 + I, 6 + J) ** 2;
            Dq := Dq + (A (2 + I, 6 + J) - B (7 + I, 1 + J)) ** 2;
         end loop;
      end loop;
      Expect (Good, "Mat_Add / Mat_Sub / Mat_Scale element-wise with offsets");
      Expect (abs (Norm_Frobenius (A) * Norm_Frobenius (A) - Sq) <= 1.0E-3 * (1.0 + Sq), "Norm_Frobenius squared = sum of squares");
      Expect (abs (Diff_Frobenius (A, B) * Diff_Frobenius (A, B) - Dq) <= 1.0E-3 * (1.0 + Dq), "Diff_Frobenius squared");
      Expect (Diff_Frobenius (A, A) = 0.0 and then Mat_Near (A, A, 0.0), "self difference 0");
      Expect (Mat_Near (A, B) = (Dq = 0.0), "Mat_Near on integer matrices");
      declare
         T : Matrix := B;
      begin
         T (7 + 3, 1 + 3) := T (7 + 3, 1 + 3) + 0.5;
         Expect (Mat_Near (B, T, 0.5) and then not Mat_Near (B, T, 0.25), "Mat_Near tolerance boundary (last entry)");
         T := B;
         T (7, 1) := T (7, 1) - 0.5;
         Expect (Mat_Near (T, B, 0.5) and then not Mat_Near (T, B, 0.49), "Mat_Near tolerance boundary (first entry)");
      end;
   end;
   declare
      M : constant Matrix (1 .. 2, 1 .. 2) := [[0.0, 3.0], [0.0, 4.0]];
      M2 : constant Matrix (1 .. 2, 1 .. 2) := [[6.0, 3.0], [2.0, 1.0]];
   begin
      Expect (Norm_Frobenius (M) = 5.0, "Norm_Frobenius [0 3; 0 4] = 5");
      Expect (Diff_Frobenius (M2, M) = 7.0, "Diff_Frobenius = sqrt (36 + 0 + 4 + 9) = 7");
   end;
   Expect (Near (0.0, 0.5, 0.5) and then Near (0.5, 0.0, 0.5) and then not Near (0.0, 0.5, 0.25)
           and then not Near (0.5, 0.0, 0.25), "Near tolerance boundary");
   for N in 1 .. Max_N loop
      declare
         A  : constant Matrix := Rand_Mat (N, 4, 9);
         Pd : constant Matrix := Pad_To_Power_Of_Two (A);
         P  : constant Positive := Pow2_Ceil (N);
         Good : Boolean := Pd'First (1) = 1 and then Pd'Length (1) = P and then Pd'Length (2) = P;
      begin
         if Good then
            for I in 1 .. P loop
               for J in 1 .. P loop
                  Good := Good and then Pd (I, J) = (if I <= N and then J <= N then A (3 + I, 8 + J) else 0.0);
               end loop;
            end loop;
            declare
               Tr : constant Matrix := Trim (Pd, N);
            begin
               Good := Good and then Tr'Length (1) = N and then Tr'Length (2) = N;
               for I in 1 .. N loop
                  for J in 1 .. N loop
                     Good := Good and then Tr (I, J) = A (3 + I, 8 + J);
                  end loop;
               end loop;
            end;
         end if;
         Expect (Good, "Pad_To_Power_Of_Two / Trim N=" & N'Image);
      end;
   end loop;
   for N in 1 .. 9 loop
      declare
         Z  : constant Matrix := Zeros (N);
         O  : constant Matrix := Ones (N, 2.5);
         Id : constant Matrix := Identity (N);
         Sf : constant Matrix := Sequential_Fill (N);
         Dt : constant Matrix := Deterministic (N, 3);
         H  : constant Matrix := Make_Hilbert (N);
         IZ : constant Int_Matrix := Int_Zeros (N);
         IO : constant Int_Matrix := Int_Ones (N, -4);
         II : constant Int_Matrix := Int_Identity (N);
         ISq : constant Int_Matrix := Int_Sequential_Fill (N);
         IDt : constant Int_Matrix := Int_Deterministic (N, 3);
         Good : Boolean := Z'Length (1) = N and then O'Length (2) = N and then Id'Length (1) = N
           and then Sf'Length (2) = N and then Dt'Length (1) = N and then H'Length (2) = N
           and then IZ'Length (1) = N and then IO'Length (2) = N and then II'Length (1) = N
           and then ISq'Length (2) = N and then IDt'Length (1) = N;
         Count : Natural := 0;
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               Count := Count + 1;   --  row-major position
               Good := Good and then Z (I, J) = 0.0 and then O (I, J) = 2.5
                 and then Id (I, J) = (if I = J then 1.0 else 0.0)
                 and then Sf (I, J) = Float (Count)
                 and then Dt (I, J) >= 0.0 and then Dt (I, J) < 1.0
                 and then abs (H (I, J) * Float (I + J - 1) - 1.0) <= 1.0E-6
                 and then IZ (I, J) = 0 and then IO (I, J) = -4
                 and then II (I, J) = (if I = J then 1 else 0)
                 and then ISq (I, J) = Count
                 and then IDt (I, J) in 0 .. 9;
            end loop;
         end loop;
         Expect (Good, "builders N=" & N'Image);
      end;
   end loop;
   ---------------------------------------------------------------- taxonomy (README tables)
   declare
      use Ada.Numerics.Elementary_Functions;
      Count : Natural := 0;
      Log2_7 : constant Float := 2.807_354_9;   --  log(7) / log(2)
      type Row is record
         Exp : Float; Run, Prac, Par, Ver : Boolean; Year : Natural;
      end record;
      Table : constant array (Method_Kind) of Row :=
        [Classical            => (3.0,    True,  True,  False, False, 0),
         Strassen             => (Log2_7, True,  True,  False, False, 1969),
         Coppersmith_Winograd => (2.3755, False, False, False, False, 1990),
         Cannon               => (3.0,    True,  True,  True,  False, 1969),
         Freivalds_Verify     => (2.0,    True,  True,  False, True,  1979),
         SUMMA                => (3.0,    False, True,  True,  False, 1995),
         Laser_Family         => (2.373,  False, False, False, False, 2010)];
   begin
      for M in Method_Kind loop
         Count := Count + 1;
         declare
            Info : constant Method_Info := Classify_Method (M);
            T    : constant Row := Table (M);
         begin
            Expect (abs (Exponent_Of (M) - T.Exp) <= 1.0E-5 and then Supports_Runnable (M) = T.Run
                    and then Is_Practical (M) = T.Prac, "taxonomy row " & M'Image);
            Expect (Info.Kind = M and then abs (Info.Exponent - T.Exp) <= 1.0E-5
                    and then Info.Practical = T.Prac and then Info.Runnable_Sketch = T.Run
                    and then Info.Is_Parallel = T.Par and then Info.Is_Verification = T.Ver
                    and then Info.Year = T.Year, "Classify_Method " & M'Image);
            for N in 1 .. Max_N loop
               declare
                  E : constant Float := Float (N) ** T.Exp;
               begin
                  Expect (abs (Estimated_Ops (N, M) - E) <= 1.0E-4 * E, "Estimated_Ops" & N'Image & " " & M'Image);
               end;
            end loop;
         end;
      end loop;
      Expect (Method_Count = Count, "Method_Count");
      for N in 1 .. Max_N loop
         Expect (Recommend_Method (N, True) = (if N >= 2 then Cannon elsif N >= 16 then Strassen else Classical)
                 and then Recommend_Method (N, False) = (if N >= 16 then Strassen else Classical),
                 "Recommend_Method" & N'Image);
      end loop;
   end;
   declare
      Years : constant array (1 .. Milestone_Count) of Natural := [1969, 1969, 1979, 1981, 1990, 1995, 2010, 2014];
      Exps  : constant array (1 .. Milestone_Count) of Float :=
        [2.807_355, 3.0, 2.0, 2.522, 2.3755, 3.0, 2.3737, 2.37286];
      function Label_Of (I : Positive) return String is
        (case I is
            when 1 => "Strassen seven-product recursion",
            when 2 => "Cannon systolic 2D-mesh multiply",
            when 3 => "Freivalds probabilistic verify",
            when 4 => "Schonhage / Pan era improvements",
            when 5 => "Coppersmith-Winograd classic bound",
            when 6 => "SUMMA scalable universal MM",
            when 7 => "Stothers laser-method refinement",
            when others => "Le Gall further laser improvement");
   begin
      for I in 1 .. Milestone_Count loop
         declare
            M : constant Milestone := Get_Milestone (I);
            L : constant String := Milestone_Label (I);
            Pad_Ok : Boolean := True;
         begin
            for K in M.Len + 1 .. M.Label'Last loop
               Pad_Ok := Pad_Ok and then M.Label (K) = ' ';
            end loop;
            Expect (M.Year = Years (I) and then abs (M.Exponent - Exps (I)) <= 1.0E-4
                    and then L = Label_Of (I) and then M.Len = Label_Of (I)'Length and then Pad_Ok,
                    "milestone" & I'Image);
         end;
      end loop;
   end;

   if Failures > 0 then
      Ada.Text_IO.Put_Line ("FAIL own checks:" & Failures'Image & " of" & Checked'Image);
      raise Program_Error with "own checks failed";
   end if;
   Ada.Text_IO.Put_Line ("PASS own checks:" & Checked'Image
                         & " (outer-product reference, closed-form counts, reference LCG, README tables)");
end Own_Checks;
