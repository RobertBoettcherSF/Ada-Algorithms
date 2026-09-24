--  Berlekamp–Rabin root finding — implementation.

pragma Ada_2022;

with Interfaces;

package body Berlekamp_Root_Finding
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Mul_Mod / Mod_Pow / Gcd / Mod_Inv
   ------------------------------------------------------------------

   function Mul_Mod (A, B, M : U64) return U64 is
      use Interfaces;
      AA, BB, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA   := Unsigned_128 (A rem M);
      BB   := Unsigned_128 (B rem M);
      MM   := Unsigned_128 (M);
      Prod := AA * BB;
      return U64 (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

   function Mod_Pow (Base, Exp, Modulus : U64) return U64 is
      Result : U64 := 1;
      B      : U64;
      E      : U64 := Exp;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;
      B := Base rem Modulus;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Mod (Result, B, Modulus);
         end if;
         B := Mul_Mod (B, B, Modulus);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   function Gcd (A, B : U64) return U64 is
      X : U64 := A;
      Y : U64 := B;
      T : U64;
   begin
      while Y /= 0 loop
         T := X rem Y;
         X := Y;
         Y := T;
      end loop;
      return X;
   end Gcd;

   function Mod_Inv (A, P : U64) return U64 is
      A_Mod : U64;
   begin
      if P < 2 then
         raise Invalid_Argument;
      end if;
      A_Mod := A rem P;
      if A_Mod = 0 then
         raise Invalid_Argument;
      end if;
      if P = 2 then
         return 1;
      end if;
      return Mod_Pow (A_Mod, P - 2, P);
   end Mod_Inv;

   ------------------------------------------------------------------
   --  Is_Prime_Trial / Validate_Prime_Modulus
   ------------------------------------------------------------------

   function Is_Prime_Trial (N : U64) return Boolean is
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      if N rem 3 = 0 then
         return False;
      end if;
      declare
         D : U64 := 5;
      begin
         while D <= N / D loop
            if N rem D = 0 or else N rem (D + 2) = 0 then
               return False;
            end if;
            D := D + 6;
         end loop;
         return True;
      end;
   end Is_Prime_Trial;

   procedure Validate_Prime_Modulus (P : U64) is
   begin
      if P < 2 then
         raise Invalid_Argument;
      end if;
      if P = 2 then
         return;
      end if;
      if (P and 1) = 0 then
         raise Invalid_Argument;
      end if;
      if P <= Max_Trial_Prime and then not Is_Prime_Trial (P) then
         raise Invalid_Argument;
      end if;
   end Validate_Prime_Modulus;

   ------------------------------------------------------------------
   --  Poly_Degree / Poly_Normalize / Make_Monic
   ------------------------------------------------------------------

   function Poly_Degree (F : Poly; P : U64) return Integer is
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      for I in reverse F'Range loop
         if F (I) rem P /= 0 then
            return Integer (I);
         end if;
      end loop;
      return -1;
   end Poly_Degree;

   function Poly_Normalize (F : Poly; P : U64) return Poly is
      D : Integer;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if F'Length = 0 then
         raise Invalid_Argument;
      end if;
      D := Poly_Degree (F, P);
      if D < 0 then
         return [0 => 0];
      end if;
      declare
         R : Poly (0 .. Natural (D));
      begin
         for I in R'Range loop
            if I in F'Range then
               R (I) := F (I) rem P;
            else
               R (I) := 0;
            end if;
         end loop;
         return R;
      end;
   end Poly_Normalize;

   function Make_Monic (F : Poly; P : U64) return Poly is
      N : constant Poly := Poly_Normalize (F, P);
      D : constant Integer := Poly_Degree (N, P);
      Inv : U64;
   begin
      if D < 0 then
         return N;
      end if;
      if N (Natural (D)) = 1 then
         return N;
      end if;
      Inv := Mod_Inv (N (Natural (D)), P);
      declare
         R : Poly (N'Range);
      begin
         for I in R'Range loop
            R (I) := Mul_Mod (N (I), Inv, P);
         end loop;
         return R;
      end;
   end Make_Monic;

   ------------------------------------------------------------------
   --  Poly_Add / Poly_Sub / Poly_Mul
   ------------------------------------------------------------------

   function Poly_Add (F, G : Poly; P : U64) return Poly is
      Max_D : Natural := 0;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if F'Length > 0 then
         Max_D := Natural'Max (Max_D, F'Last);
      end if;
      if G'Length > 0 then
         Max_D := Natural'Max (Max_D, G'Last);
      end if;
      declare
         R : Poly (0 .. Max_D) := [others => 0];
      begin
         for I in F'Range loop
            R (I) := F (I) rem P;
         end loop;
         for I in G'Range loop
            R (I) := (R (I) + (G (I) rem P)) rem P;
         end loop;
         return Poly_Normalize (R, P);
      end;
   end Poly_Add;

   function Poly_Sub (F, G : Poly; P : U64) return Poly is
      Max_D : Natural := 0;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if F'Length > 0 then
         Max_D := Natural'Max (Max_D, F'Last);
      end if;
      if G'Length > 0 then
         Max_D := Natural'Max (Max_D, G'Last);
      end if;
      declare
         R : Poly (0 .. Max_D) := [others => 0];
      begin
         for I in F'Range loop
            R (I) := F (I) rem P;
         end loop;
         for I in G'Range loop
            R (I) := (R (I) + P - (G (I) rem P)) rem P;
         end loop;
         return Poly_Normalize (R, P);
      end;
   end Poly_Sub;

   function Poly_Mul (F, G : Poly; P : U64) return Poly is
      DF : constant Integer := Poly_Degree (F, P);
      DG : constant Integer := Poly_Degree (G, P);
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if DF < 0 or else DG < 0 then
         return [0 => 0];
      end if;
      declare
         R : Poly (0 .. Natural (DF + DG)) := [others => 0];
      begin
         for I in 0 .. Natural (DF) loop
            for J in 0 .. Natural (DG) loop
               declare
                  FI : constant U64 :=
                    (if I in F'Range then F (I) rem P else 0);
                  GJ : constant U64 :=
                    (if J in G'Range then G (J) rem P else 0);
               begin
                  R (I + J) := (R (I + J) + Mul_Mod (FI, GJ, P)) rem P;
               end;
            end loop;
         end loop;
         return Poly_Normalize (R, P);
      end;
   end Poly_Mul;

   ------------------------------------------------------------------
   --  Poly_Mod / Poly_Quotient
   ------------------------------------------------------------------

   function Poly_Mod (A, M : Poly; P : U64) return Poly is
      DM : constant Integer := Poly_Degree (M, P);
      DA : constant Integer := Poly_Degree (A, P);
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if DM < 0 then
         raise Invalid_Argument;
      end if;
      if DA < 0 then
         return [0 => 0];
      end if;
      if DA < DM then
         return Poly_Normalize (A, P);
      end if;
      declare
         MM       : constant Poly := Poly_Normalize (M, P);
         Lead_Inv : constant U64 := Mod_Inv (MM (Natural (DM)), P);
         Buf      : array (0 .. Natural (DA)) of U64 := [others => 0];
         Cur_Deg  : Integer := DA;
      begin
         for I in A'Range loop
            if I <= Buf'Last then
               Buf (I) := A (I) rem P;
            end if;
         end loop;
         while Cur_Deg >= DM loop
            declare
               Diff  : constant Natural := Natural (Cur_Deg - DM);
               Scale : constant U64 :=
                 Mul_Mod (Buf (Natural (Cur_Deg)), Lead_Inv, P);
            begin
               for K in 0 .. Natural (DM) loop
                  declare
                     Idx  : constant Natural := K + Diff;
                     Term : constant U64 := Mul_Mod (MM (K), Scale, P);
                  begin
                     Buf (Idx) := (Buf (Idx) + P - Term) rem P;
                  end;
               end loop;
               --  recompute degree
               Cur_Deg := -1;
               for I in reverse Buf'Range loop
                  if Buf (I) /= 0 then
                     Cur_Deg := Integer (I);
                     exit;
                  end if;
               end loop;
            end;
         end loop;
         if Cur_Deg < 0 then
            return [0 => 0];
         end if;
         declare
            R : Poly (0 .. Natural (Cur_Deg));
         begin
            for I in R'Range loop
               R (I) := Buf (I);
            end loop;
            return R;
         end;
      end;
   end Poly_Mod;

   function Poly_Quotient (A, M : Poly; P : U64) return Poly is
      DA : constant Integer := Poly_Degree (A, P);
      DM : constant Integer := Poly_Degree (M, P);
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if DM < 0 then
         raise Invalid_Argument;
      end if;
      if DA < 0 then
         return [0 => 0];
      end if;
      if DA < DM then
         raise Invalid_Argument;
      end if;
      declare
         MM       : constant Poly := Poly_Normalize (M, P);
         Lead_Inv : constant U64 := Mod_Inv (MM (Natural (DM)), P);
         Buf      : array (0 .. Natural (DA)) of U64 := [others => 0];
         Q        : array (0 .. Natural (DA - DM)) of U64 := [others => 0];
         Cur_Deg  : Integer := DA;
      begin
         for I in A'Range loop
            if I <= Buf'Last then
               Buf (I) := A (I) rem P;
            end if;
         end loop;
         while Cur_Deg >= DM loop
            declare
               Diff  : constant Natural := Natural (Cur_Deg - DM);
               Scale : constant U64 :=
                 Mul_Mod (Buf (Natural (Cur_Deg)), Lead_Inv, P);
            begin
               Q (Diff) := (Q (Diff) + Scale) rem P;
               for K in 0 .. Natural (DM) loop
                  declare
                     Idx  : constant Natural := K + Diff;
                     Term : constant U64 := Mul_Mod (MM (K), Scale, P);
                  begin
                     Buf (Idx) := (Buf (Idx) + P - Term) rem P;
                  end;
               end loop;
               Cur_Deg := -1;
               for I in reverse Buf'Range loop
                  if Buf (I) /= 0 then
                     Cur_Deg := Integer (I);
                     exit;
                  end if;
               end loop;
            end;
         end loop;
         if Cur_Deg >= 0 then
            raise Invalid_Argument;
         end if;
         declare
            Tmp : Poly (0 .. Natural (DA - DM));
         begin
            for I in Tmp'Range loop
               Tmp (I) := Q (I);
            end loop;
            return Poly_Normalize (Tmp, P);
         end;
      end;
   end Poly_Quotient;

   ------------------------------------------------------------------
   --  Poly_Gcd / Poly_Mod_Pow / Poly_Derivative / Poly_Eval
   ------------------------------------------------------------------

   function Poly_Gcd (F, G : Poly; P : U64) return Poly is
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      declare
         B_Deg : constant Integer := Poly_Degree (G, P);
      begin
         if B_Deg < 0 then
            return Make_Monic (Poly_Normalize (F, P), P);
         end if;
         return Poly_Gcd (G, Poly_Mod (F, G, P), P);
      end;
   end Poly_Gcd;

   function Poly_Mod_Pow
     (Base    : Poly;
      Exp     : U64;
      Modulus : Poly;
      P       : U64) return Poly
   is
      DM : constant Integer := Poly_Degree (Modulus, P);

      function Pow_Rec (Res, Bb : Poly; Ee : U64) return Poly is
      begin
         if Ee = 0 then
            return Res;
         elsif (Ee and 1) = 1 then
            return Pow_Rec
              (Poly_Mod (Poly_Mul (Res, Bb, P), Modulus, P),
               Poly_Mod (Poly_Mul (Bb, Bb, P), Modulus, P),
               Ee / 2);
         else
            return Pow_Rec
              (Res,
               Poly_Mod (Poly_Mul (Bb, Bb, P), Modulus, P),
               Ee / 2);
         end if;
      end Pow_Rec;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if DM < 0 then
         raise Invalid_Argument;
      end if;
      if DM = 0 then
         return [0 => 0];
      end if;
      if Exp = 0 then
         return [0 => 1];
      end if;
      return Pow_Rec
        ([0 => 1], Poly_Mod (Base, Modulus, P), Exp);
   end Poly_Mod_Pow;

   function Poly_Derivative (F : Poly; P : U64) return Poly is
      D : constant Integer := Poly_Degree (F, P);
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if D <= 0 then
         return [0 => 0];
      end if;
      declare
         R : Poly (0 .. Natural (D - 1)) := [others => 0];
      begin
         for I in 1 .. Natural (D) loop
            declare
               Coeff : constant U64 :=
                 (if I in F'Range then F (I) rem P else 0);
            begin
               R (I - 1) := Mul_Mod (U64 (I), Coeff, P);
            end;
         end loop;
         return Poly_Normalize (R, P);
      end;
   end Poly_Derivative;

   function Poly_Eval (F : Poly; X, P : U64) return U64 is
      Acc : U64 := 0;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if F'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in reverse F'Range loop
         Acc := Mul_Mod (Acc, X, P);
         Acc := (Acc + (F (I) rem P)) rem P;
      end loop;
      return Acc;
   end Poly_Eval;

   function Poly_Square_Free (F : Poly; P : U64) return Poly is
      N   : constant Poly := Poly_Normalize (F, P);
      Der : constant Poly := Poly_Derivative (N, P);
      G   : constant Poly := Poly_Gcd (N, Der, P);
   begin
      if Poly_Degree (G, P) <= 0 then
         return Make_Monic (N, P);
      end if;
      return Make_Monic (Poly_Quotient (N, G, P), P);
   end Poly_Square_Free;

   ------------------------------------------------------------------
   --  Poly_Shift: F(x − Z)
   ------------------------------------------------------------------

   function Poly_Shift (F : Poly; Z, P : U64) return Poly is
      N  : constant Poly := Poly_Normalize (F, P);
      D  : constant Integer := Poly_Degree (N, P);
      Zm : U64;
   begin
      if P = 0 then
         raise Invalid_Argument;
      end if;
      if D < 0 then
         return [0 => 0];
      end if;
      Zm := Z rem P;
      if Zm = 0 then
         return N;
      end if;
      --  Horner: accumulate in a fixed buffer of size deg+1
      declare
         Buf : array (0 .. Natural (D)) of U64 := [others => 0];
         Len : Natural := 0;  -- current degree of accumulator
      begin
         Buf (0) := N (Natural (D));
         Len := 0;
         for K in reverse 0 .. Natural (D) - 1 loop
            --  multiply by (x − Zm): shift up, then subtract Zm * old
            declare
               New_Buf : array (0 .. Natural (D)) of U64 := [others => 0];
            begin
               for I in 0 .. Len loop
                  New_Buf (I + 1) := Buf (I);
               end loop;
               for I in 0 .. Len loop
                  New_Buf (I) :=
                    (New_Buf (I) + P - Mul_Mod (Buf (I), Zm, P)) rem P;
               end loop;
               New_Buf (0) := (New_Buf (0) + (N (K) rem P)) rem P;
               Len := Len + 1;
               for I in 0 .. Len loop
                  Buf (I) := New_Buf (I);
               end loop;
               --  trim leading zeros (should not happen mid-Horner often)
               while Len > 0 and then Buf (Len) = 0 loop
                  Len := Len - 1;
               end loop;
            end;
         end loop;
         declare
            R : Poly (0 .. Len);
         begin
            for I in R'Range loop
               R (I) := Buf (I);
            end loop;
            return Poly_Normalize (R, P);
         end;
      end;
   end Poly_Shift;

   ------------------------------------------------------------------
   --  Root buffer + LCG
   ------------------------------------------------------------------

   type Root_Buf is array (Natural range 0 .. 63) of U64;

   procedure Append_Unique
     (Buf   : in out Root_Buf;
      Count : in out Natural;
      R     : U64)
   is
   begin
      for I in 0 .. Count - 1 loop
         if Buf (I) = R then
            return;
         end if;
      end loop;
      if Count > Buf'Last then
         raise Invalid_Argument;
      end if;
      Buf (Count) := R;
      Count := Count + 1;
   end Append_Unique;

   function Buf_To_List
     (Buf   : Root_Buf;
      Count : Natural) return Root_List
   is
   begin
      if Count = 0 then
         return [1 .. 0 => 0];
      end if;
      declare
         Out_R : Root_List (0 .. Count - 1);
      begin
         for I in Out_R'Range loop
            Out_R (I) := Buf (I);
         end loop;
         return Out_R;
      end;
   end Buf_To_List;

   type LCG_State is record
      S : U64 := 1;
   end record;

   procedure LCG_Next (St : in out LCG_State) is
   begin
      St.S := St.S * 6364136223846793005 + 1;
   end LCG_Next;

   function LCG_Mod (St : in out LCG_State; M : U64) return U64 is
   begin
      LCG_Next (St);
      if M = 0 then
         return 0;
      end if;
      return St.S rem M;
   end LCG_Mod;

   ------------------------------------------------------------------
   --  Recursive Berlekamp–Rabin split
   ------------------------------------------------------------------

   procedure Collect_Roots
     (F            : Poly;
      P            : U64;
      Max_Attempts : Positive;
      St           : in out LCG_State;
      Buf          : in out Root_Buf;
      Count        : in out Natural)
   is
      N : constant Poly := Make_Monic (Poly_Normalize (F, P), P);
      D : constant Integer := Poly_Degree (N, P);
   begin
      if D < 0 or else D = 0 then
         return;
      end if;

      if D = 1 then
         declare
            Root : constant U64 :=
              Mul_Mod ((P - (N (0) rem P)) rem P, Mod_Inv (N (1), P), P);
         begin
            Append_Unique (Buf, Count, Root);
         end;
         return;
      end if;

      if N (0) = 0 then
         Append_Unique (Buf, Count, 0);
         declare
            Q : Poly (0 .. Natural (D - 1));
         begin
            for I in Q'Range loop
               Q (I) := N (I + 1);
            end loop;
            Collect_Roots (Q, P, Max_Attempts, St, Buf, Count);
         end;
         return;
      end if;

      if P = 2 then
         if Poly_Eval (N, 1, P) = 0 then
            Append_Unique (Buf, Count, 1);
         end if;
         return;
      end if;

      declare
         Attempts : Natural := 0;
         Half     : constant U64 := (P - 1) / 2;
         X_Poly   : constant Poly := [0 => 0, 1 => 1];
         One_Poly : constant Poly := [0 => 1];
      begin
         while Attempts < Max_Attempts loop
            Attempts := Attempts + 1;
            declare
               Z  : constant U64 := LCG_Mod (St, P);
               Fz : constant Poly := Poly_Shift (N, Z, P);
               Df : constant Integer := Poly_Degree (Fz, P);
               Split_Done : Boolean := False;
            begin
               if Df > 0 then
                  if Fz (0) = 0 then
                     --  Fz(0)=F(-Z)=0 ⇒ original root λ ≡ -Z (mod P)
                     declare
                        Root : constant U64 := (P - (Z rem P)) rem P;
                        Linear : constant Poly :=
                          [0 => (P - Root) rem P, 1 => 1];
                        Quot : constant Poly :=
                          Poly_Quotient (N, Linear, P);
                     begin
                        Append_Unique (Buf, Count, Root);
                        Collect_Roots
                          (Quot, P, Max_Attempts, St, Buf, Count);
                     end;
                     return;
                  end if;

                  declare
                     Xp : constant Poly :=
                       Poly_Mod_Pow (X_Poly, Half, Fz, P);
                     Gm : constant Poly :=
                       Poly_Gcd (Poly_Sub (Xp, One_Poly, P), Fz, P);
                     Dg : constant Integer := Poly_Degree (Gm, P);
                  begin
                     if Dg > 0 and then Dg < Df then
                        declare
                           Z_Back : constant U64 :=
                             (P - (Z rem P)) rem P;
                           G_Back : constant Poly :=
                             Poly_Shift (Gm, Z_Back, P);
                           H_Fz : constant Poly :=
                             Poly_Quotient (Fz, Gm, P);
                           H_Back : constant Poly :=
                             Poly_Shift (H_Fz, Z_Back, P);
                        begin
                           Collect_Roots
                             (G_Back, P, Max_Attempts, St, Buf, Count);
                           Collect_Roots
                             (H_Back, P, Max_Attempts, St, Buf, Count);
                        end;
                        Split_Done := True;
                     else
                        declare
                           Gp : constant Poly :=
                             Poly_Gcd
                               (Poly_Add (Xp, One_Poly, P), Fz, P);
                           Dp : constant Integer := Poly_Degree (Gp, P);
                        begin
                           if Dp > 0 and then Dp < Df then
                              declare
                                 Z_Back : constant U64 :=
                                   (P - (Z rem P)) rem P;
                                 G_Back : constant Poly :=
                                   Poly_Shift (Gp, Z_Back, P);
                                 H_Fz : constant Poly :=
                                   Poly_Quotient (Fz, Gp, P);
                                 H_Back : constant Poly :=
                                   Poly_Shift (H_Fz, Z_Back, P);
                              begin
                                 Collect_Roots
                                   (G_Back, P, Max_Attempts, St,
                                    Buf, Count);
                                 Collect_Roots
                                   (H_Back, P, Max_Attempts, St,
                                    Buf, Count);
                              end;
                              Split_Done := True;
                           end if;
                        end;
                     end if;
                  end;
               end if;
               if Split_Done then
                  return;
               end if;
            end;
         end loop;
      end;
   end Collect_Roots;

   ------------------------------------------------------------------
   --  Public root finders
   ------------------------------------------------------------------

   function Find_Roots
     (F            : Poly;
      P            : U64;
      Max_Attempts : Positive := Default_Max_Attempts;
      Seed         : U64     := 1) return Root_List
   is
      Buf   : Root_Buf := [others => 0];
      Count : Natural := 0;
      St    : LCG_State;
   begin
      if F'Length = 0 then
         raise Invalid_Argument;
      end if;
      Validate_Prime_Modulus (P);

      if Poly_Degree (F, P) < 0 then
         raise Invalid_Argument;
      end if;

      --  p=2: F' often vanishes; just evaluate the two field elements.
      if P = 2 then
         declare
            X : U64 := 0;
         begin
            loop
               if Poly_Eval (F, X, P) = 0 then
                  Append_Unique (Buf, Count, X);
               end if;
               exit when X = 1;
               X := 1;
            end loop;
            return Buf_To_List (Buf, Count);
         end;
      end if;

      declare
         Sf : constant Poly := Poly_Square_Free (F, P);
      begin
         if Poly_Degree (Sf, P) <= 0 then
            return [1 .. 0 => 0];
         end if;

         St.S := Seed;
         if St.S = 0 then
            St.S := 1;
         end if;

         Collect_Roots (Sf, P, Max_Attempts, St, Buf, Count);
         return Buf_To_List (Buf, Count);
      end;
   end Find_Roots;

   function Find_Roots_Deterministic_Small
     (F : Poly;
      P : U64) return Root_List
   is
      Buf   : Root_Buf := [others => 0];
      Count : Natural := 0;
      X     : U64;
   begin
      if F'Length = 0 then
         raise Invalid_Argument;
      end if;
      Validate_Prime_Modulus (P);
      if P > Max_Brute_P then
         raise Invalid_Argument;
      end if;
      if Poly_Degree (F, P) < 0 then
         raise Invalid_Argument;
      end if;

      X := 0;
      loop
         if Poly_Eval (F, X, P) = 0 then
            Append_Unique (Buf, Count, X);
         end if;
         exit when X = P - 1;
         X := X + 1;
      end loop;
      return Buf_To_List (Buf, Count);
   end Find_Roots_Deterministic_Small;

end Berlekamp_Root_Finding;
