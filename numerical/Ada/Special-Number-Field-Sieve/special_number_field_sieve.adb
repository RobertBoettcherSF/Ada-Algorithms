--  Special Number Field Sieve — Ada 2023 body (educational toy).

pragma Ada_2022;

with Interfaces;

package body Special_Number_Field_Sieve
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy names
   ------------------------------------------------------------------

   function Form_Name (K : Special_Form_Kind) return String is
   begin
      case K is
         when Not_Special =>
            return "Not special";
         when Mersenne_Like =>
            return "Mersenne-like (2^k - 1)";
         when Fermat_Like =>
            return "Fermat-like (2^(2^k) + 1)";
         when Power_Difference =>
            return "Power difference (a^e - b^e)";
         when Power_Sum =>
            return "Power sum (a^e + b^e)";
      end case;
   end Form_Name;

   ------------------------------------------------------------------
   --  Mul_Mod / Mod_Pow / Gcd / Floor_Sqrt
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

   function Floor_Sqrt (N : U64) return U64 is
      Lo  : U64 := 0;
      Hi  : U64 := N;
      Mid : U64;
   begin
      if N = 0 or else N = 1 then
         return N;
      end if;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > 0 and then Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   ------------------------------------------------------------------
   --  Trial helpers
   ------------------------------------------------------------------

   function Is_Prime_Trial (N : U64) return Boolean is
      D    : U64;
      Root : U64;
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
      Root := Floor_Sqrt (N);
      D := 5;
      while D <= Root loop
         if N rem D = 0 then
            return False;
         end if;
         if D + 2 <= Root and then N rem (D + 2) = 0 then
            return False;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime_Trial;

   function Smallest_Prime_Factor (N : U64) return U64 is
      D    : U64;
      Root : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;
      Root := Floor_Sqrt (N);
      D := 5;
      while D <= Root loop
         if N rem D = 0 then
            return D;
         end if;
         if D + 2 <= Root and then N rem (D + 2) = 0 then
            return D + 2;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return N;
   end Smallest_Prime_Factor;

   ------------------------------------------------------------------
   --  Safe power for tiny special-form search
   ------------------------------------------------------------------

   --  Compute Base^Exp in U64; return False on overflow / Base^Exp > Cap
   --  when Cap > 0. Cap = 0 means only overflow of U64 is checked.
   function Safe_Pow
     (Base : U64;
      Exp  : Natural;
      Cap  : U64;
      Out_V : out U64) return Boolean
   is
      R : U64 := 1;
      B : U64 := Base;
      E : Natural := Exp;
   begin
      Out_V := 0;
      if Exp = 0 then
         Out_V := 1;
         return Cap = 0 or else 1 <= Cap;
      end if;
      if Base = 0 then
         Out_V := 0;
         return True;
      end if;
      while E > 0 loop
         if (E rem 2) = 1 then
            if R > 0 and then B > U64'Last / R then
               return False;
            end if;
            R := R * B;
            if Cap > 0 and then R > Cap then
               return False;
            end if;
         end if;
         E := E / 2;
         if E > 0 then
            if B > U64'Last / B then
               return False;
            end if;
            B := B * B;
         end if;
      end loop;
      Out_V := R;
      if Cap > 0 and then R > Cap then
         return False;
      end if;
      return True;
   end Safe_Pow;

   ------------------------------------------------------------------
   --  Special-form detectors
   ------------------------------------------------------------------

   function Is_Mersenne_Like (N : U64) return Boolean is
      --  N = 2^K − 1  ⇔  N+1 is a power of two, K ≥ 2 ⇔ N ≥ 3.
      M : U64;
   begin
      if N < 3 then
         return False;
      end if;
      if N = U64'Last then
         --  2^64 − 1 is Mersenne-like.
         return True;
      end if;
      M := N + 1;
      return (M and (M - 1)) = 0;
   end Is_Mersenne_Like;

   function Is_Fermat_Like (N : U64) return Boolean is
      --  F_k = 2^(2^k) + 1 for k = 0..5 (F5 = 2^32 + 1 fits U64).
      Pow2 : U64 := 1;  --  2^k as exponent for the outer 2^(…)
      F    : U64;
   begin
      if N < 3 then
         return False;
      end if;
      for K in 0 .. 5 loop
         --  F = 2^(2^K) + 1
         if not Safe_Pow (2, Natural (Pow2), 0, F) then
            return False;
         end if;
         if F = U64'Last then
            null;  --  cannot add 1
         elsif F + 1 = N then
            return True;
         end if;
         if Pow2 > U64'Last / 2 then
            exit;
         end if;
         Pow2 := Pow2 * 2;
      end loop;
      return False;
   end Is_Fermat_Like;

   function Is_Power_Difference (N : U64) return Boolean is
      AE, BE : U64;
      Ok_A, Ok_B : Boolean;
   begin
      if N < 3 then
         return False;
      end if;
      for E in 2 .. 12 loop
         for A in U64 range 2 .. 32 loop
            Ok_A := Safe_Pow (A, E, 0, AE);
            if not Ok_A then
               --  A^E overflowed; larger A only worse for fixed E.
               exit;
            end if;
            --  Need AE - BE = N with BE = B^E ≥ 1, so AE ≥ N + 1.
            if AE >= N + 1 then
               for B in U64 range 1 .. A - 1 loop
                  Ok_B := Safe_Pow (B, E, AE, BE);
                  if Ok_B and then AE >= BE and then AE - BE = N then
                     return True;
                  end if;
               end loop;
            end if;
         end loop;
      end loop;
      return False;
   end Is_Power_Difference;

   function Is_Power_Sum (N : U64) return Boolean is
      AE, BE, Sum : U64;
      Ok_A, Ok_B  : Boolean;
   begin
      if N < 2 then
         return False;
      end if;
      for E in 2 .. 12 loop
         for A in U64 range 1 .. 32 loop
            Ok_A := Safe_Pow (A, E, N, AE);
            if not Ok_A then
               exit;  --  larger A worse
            end if;
            for B in U64 range 1 .. A loop
               Ok_B := Safe_Pow (B, E, N, BE);
               if Ok_B then
                  if AE > U64'Last - BE then
                     null;
                  else
                     Sum := AE + BE;
                     if Sum = N then
                        return True;
                     end if;
                  end if;
               end if;
            end loop;
         end loop;
      end loop;
      return False;
   end Is_Power_Sum;

   function Classify_Special_Form (N : U64) return Special_Form_Kind is
   begin
      if Is_Mersenne_Like (N) then
         return Mersenne_Like;
      elsif Is_Fermat_Like (N) then
         return Fermat_Like;
      elsif Is_Power_Difference (N) then
         return Power_Difference;
      elsif Is_Power_Sum (N) then
         return Power_Sum;
      else
         return Not_Special;
      end if;
   end Classify_Special_Form;

   function Is_Special_Form (N : U64) return Boolean is
   begin
      return Classify_Special_Form (N) /= Not_Special;
   end Is_Special_Form;

   ------------------------------------------------------------------
   --  Factor base / smoothness
   ------------------------------------------------------------------

   function Primes_Up_To (B : U64) return Factor_Base is
      --  Count then fill (educational trial sieve). Cap length for toys.
      Max_Count : constant Natural := 256;
      Buf       : array (1 .. Max_Count) of U64;
      Count     : Natural := 0;
   begin
      if B < 2 then
         declare
            Empty : Factor_Base (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      for C in U64 range 2 .. B loop
         if Is_Prime_Trial (C) then
            Count := Count + 1;
            Buf (Count) := C;
            exit when Count = Max_Count;
         end if;
      end loop;
      declare
         Result : Factor_Base (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Buf (I);
         end loop;
         return Result;
      end;
   end Primes_Up_To;

   function Is_B_Smooth (N : U64; Base : Factor_Base) return Boolean is
      M : U64;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return True;
      end if;
      M := N;
      for P of Base loop
         if P < 2 then
            raise Invalid_Argument;
         end if;
         while M rem P = 0 loop
            M := M / P;
         end loop;
         exit when M = 1;
      end loop;
      return M = 1;
   end Is_B_Smooth;

   function Smooth_Exponents
     (N : U64; Base : Factor_Base) return Exponent_Vector
   is
      M : U64;
      E : Exponent_Vector (Base'Range);
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if Base'Length = 0 and then N /= 1 then
         raise Invalid_Argument;
      end if;
      M := N;
      for I in Base'Range loop
         declare
            P : constant U64 := Base (I);
            C : Natural := 0;
         begin
            if P < 2 then
               raise Invalid_Argument;
            end if;
            while M rem P = 0 loop
               C := C + 1;
               M := M / P;
            end loop;
            E (I) := C;
         end;
      end loop;
      if M /= 1 then
         raise Invalid_Argument;
      end if;
      return E;
   end Smooth_Exponents;

   ------------------------------------------------------------------
   --  GF(2) dependency search (tiny educational Gaussian elimination)
   ------------------------------------------------------------------

   --  Max supported factor-base / relation width for the toy solver.
   Max_FB : constant := 64;

   type Bit_Row is array (1 .. Max_FB) of Boolean;
   type Bit_Matrix is array (Positive range <>) of Bit_Row;
   type Bool_Vec is array (Positive range <>) of Boolean;
   --  Augmented matrix: columns 1..Cols are exponent parities; column
   --  Cols+1 .. Cols+Rows track which original relations are in the combo
   --  (identity). We store relation-mask separately as Bit_Row of width
   --  Max_FB for simplicity when Rows ≤ Max_FB.
   procedure Find_Dependency
     (Parity     : Bit_Matrix;
      Cols       : Natural;
      Rows       : Natural;
      Found      : out Boolean;
      Combo      : out Bit_Row)
   is
      --  Working matrix W(i)(1..Cols) = parity; Mask(i)(1..Rows) = combo.
      type Wide_Row is record
         P : Bit_Row;
         M : Bit_Row;
      end record;
      W     : array (1 .. Max_FB) of Wide_Row;
      R, C  : Natural;
   begin
      Found := False;
      Combo := [others => False];
      if Rows = 0 or else Cols = 0 or else Rows > Max_FB or else Cols > Max_FB
      then
         return;
      end if;

      for I in 1 .. Rows loop
         W (I).P := Parity (I);
         W (I).M := [others => False];
         W (I).M (I) := True;
      end loop;

      R := 1;
      C := 1;
      while R <= Rows and then C <= Cols loop
         declare
            Pivot_Row : Natural := 0;
         begin
            for I in R .. Rows loop
               if W (I).P (C) then
                  Pivot_Row := I;
                  exit;
               end if;
            end loop;
            if Pivot_Row = 0 then
               C := C + 1;
            else
               if Pivot_Row /= R then
                  declare
                     Tmp : constant Wide_Row := W (R);
                  begin
                     W (R) := W (Pivot_Row);
                     W (Pivot_Row) := Tmp;
                  end;
               end if;
               for I in 1 .. Rows loop
                  if I /= R and then W (I).P (C) then
                     for J in 1 .. Cols loop
                        W (I).P (J) := W (I).P (J) xor W (R).P (J);
                     end loop;
                     for J in 1 .. Rows loop
                        W (I).M (J) := W (I).M (J) xor W (R).M (J);
                     end loop;
                  end if;
               end loop;
               R := R + 1;
               C := C + 1;
            end if;
         end;
      end loop;

      --  Any all-zero parity row with nonempty mask is a dependency.
      for I in 1 .. Rows loop
         declare
            All_Zero : Boolean := True;
            Any_Mask : Boolean := False;
         begin
            for J in 1 .. Cols loop
               if W (I).P (J) then
                  All_Zero := False;
                  exit;
               end if;
            end loop;
            if All_Zero then
               for J in 1 .. Rows loop
                  if W (I).M (J) then
                     Any_Mask := True;
                     exit;
                  end if;
               end loop;
            end if;
            if All_Zero and then Any_Mask then
               Found := True;
               Combo := W (I).M;
               return;
            end if;
         end;
      end loop;
   end Find_Dependency;

   ------------------------------------------------------------------
   --  Factor_Via_Congruence_Of_Squares
   ------------------------------------------------------------------

   function Factor_Via_Congruence_Of_Squares
     (N         : U64;
      Relations : Relation_List;
      Base      : Factor_Base) return U64
   is
      Rows : constant Natural := Relations'Length;
      Cols : constant Natural := Base'Length;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if Cols = 0 or else Rows = 0 then
         raise Invalid_Argument;
      end if;
      if Rows > Max_FB or else Cols > Max_FB then
         raise Invalid_Argument;
      end if;

      --  Validate primes in Base.
      for P of Base loop
         if P < 2 then
            raise Invalid_Argument;
         end if;
      end loop;

      declare
         Parity : Bit_Matrix (1 .. Rows);
         Exps   : array (1 .. Rows) of Exponent_Vector (Base'Range);
         Found  : Boolean;
         Combo  : Bit_Row;
      begin
         for I in 1 .. Rows loop
            declare
               Rel : constant Relation :=
                 Relations (Relations'First + (I - 1));
               X2  : constant U64 := Mul_Mod (Rel.X, Rel.X, N);
            begin
               if Rel.Q /= X2 then
                  raise Invalid_Argument;
               end if;
               if not Is_B_Smooth (Rel.Q, Base) then
                  raise Invalid_Argument;
               end if;
               Exps (I) := Smooth_Exponents (Rel.Q, Base);
               Parity (I) := [others => False];
               for J in Base'Range loop
                  declare
                     Col : constant Positive :=
                       1 + (J - Base'First);
                  begin
                     Parity (I)(Col) := (Exps (I)(J) rem 2) = 1;
                  end;
               end loop;
            end;
         end loop;

         --  Try several dependencies: after finding one, zero that combo
         --  out by removing a relation and retry (simple educational loop).
         declare
            Active : Bool_Vec (1 .. Rows) := [others => True];
            Attempt : Natural := 0;
         begin
            while Attempt < Rows loop
               Attempt := Attempt + 1;
               declare
                  --  Compact active rows into a submatrix.
                  Sub_Count : Natural := 0;
                  Map       : array (1 .. Max_FB) of Positive;
                  Sub_Par   : Bit_Matrix (1 .. Rows);
               begin
                  for I in 1 .. Rows loop
                     if Active (I) then
                        Sub_Count := Sub_Count + 1;
                        Map (Sub_Count) := I;
                        Sub_Par (Sub_Count) := Parity (I);
                     end if;
                  end loop;
                  if Sub_Count = 0 then
                     return 0;
                  end if;

                  Find_Dependency
                    (Parity => Sub_Par,
                     Cols   => Cols,
                     Rows   => Sub_Count,
                     Found  => Found,
                     Combo  => Combo);

                  if not Found then
                     return 0;
                  end if;

                  --  Map combo bits back to original relation indices.
                  declare
                     Use_Orig : Bit_Row := [others => False];
                     Left     : U64 := 1;
                     --  Product of Q_i for selected relations (full ints).
                     --  Then take integer square root via half-exponents.
                     Total_E  : Exponent_Vector (Base'Range) :=
                       [others => 0];
                     Right    : U64 := 1;
                     Diff     : U64;
                     G        : U64;
                     Any      : Boolean := False;
                  begin
                     for S in 1 .. Sub_Count loop
                        if Combo (S) then
                           Use_Orig (Map (S)) := True;
                           Any := True;
                        end if;
                     end loop;
                     if not Any then
                        return 0;
                     end if;

                     for I in 1 .. Rows loop
                        if Use_Orig (I) then
                           declare
                              Rel : constant Relation :=
                                Relations (Relations'First + (I - 1));
                           begin
                              Left := Mul_Mod (Left, Rel.X, N);
                              for J in Base'Range loop
                                 Total_E (J) :=
                                   Total_E (J) + Exps (I)(J);
                              end loop;
                           end;
                        end if;
                     end loop;

                     --  Build Y = product p^(e/2); all e even by construction.
                     for J in Base'Range loop
                        if (Total_E (J) rem 2) /= 0 then
                           --  Should not happen for a true dependency.
                           goto Next_Attempt;
                        end if;
                        declare
                           Half : constant Natural := Total_E (J) / 2;
                           P    : constant U64 := Base (J);
                        begin
                           for K in 1 .. Half loop
                              Right := Mul_Mod (Right, P, N);
                           end loop;
                        end;
                     end loop;

                     declare
                        Sum_Mod : U64;
                        Trivial : Boolean;
                     begin
                        --  Left, Right ∈ [0, N). Sum ≡ 0 (mod N) ⇒ Left+Right = N
                        --  (or both 0) since Left+Right < 2N.
                        if Left = 0 then
                           Sum_Mod := Right;
                        elsif Right >= N - Left then
                           Sum_Mod := Right - (N - Left);
                        else
                           Sum_Mod := Left + Right;
                        end if;
                        Trivial := Left = Right or else Sum_Mod = 0;
                        if not Trivial then
                           if Left >= Right then
                              Diff := Left - Right;
                           else
                              Diff := Right - Left;
                           end if;
                           G := Gcd (Diff, N);
                           if G > 1 and then G < N then
                              return G;
                           end if;
                           G := Gcd (Sum_Mod, N);
                           if G > 1 and then G < N then
                              return G;
                           end if;
                        end if;
                     end;

                     --  Deactivate one relation from this combo and retry.
                     for I in 1 .. Rows loop
                        if Use_Orig (I) and then Active (I) then
                           Active (I) := False;
                           exit;
                        end if;
                     end loop;
                  end;
               end;
               <<Next_Attempt>>
            end loop;
         end;
         return 0;
      end;
   end Factor_Via_Congruence_Of_Squares;

   ------------------------------------------------------------------
   --  Toy_Factor_SNFS_Like
   ------------------------------------------------------------------

   function Toy_Factor_SNFS_Like
     (N          : U64;
      Smoothness : U64 := 50) return U64
   is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N > Toy_Factor_Max then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         return 0;
      end if;
      if N = 2 or else N = 3 then
         return 0;  --  prime
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if Is_Prime_Trial (N) then
         return 0;
      end if;

      declare
         B        : constant U64 :=
           (if Smoothness < 3 then 3 else Smoothness);
         Base     : constant Factor_Base := Primes_Up_To (B);
         Need     : constant Natural :=
           Natural'Min (Max_FB, Base'Length + 5);
         Root     : constant U64 := Floor_Sqrt (N);
         Start_X  : constant U64 := Root + 1;
         Buf      : array (1 .. Max_FB) of Relation;
         Count    : Natural := 0;
         X        : U64 := Start_X;
         Scan_Max : constant U64 :=
           (if N > 500_000 then N else N * 2);
         --  Cap scan iterations for classroom runtime.
         Iters    : Natural := 0;
         Max_Iters : constant Natural := 200_000;
         Factor   : U64;
      begin
         if Base'Length = 0 then
            return Smallest_Prime_Factor (N);
         end if;

         while Count < Need and then X < Scan_Max and then Iters < Max_Iters
         loop
            Iters := Iters + 1;
            declare
               Q : constant U64 := Mul_Mod (X, X, N);
            begin
               if Q > 0 and then Is_B_Smooth (Q, Base) then
                  Count := Count + 1;
                  Buf (Count) := (X => X, Q => Q);
               end if;
            end;
            if X = U64'Last then
               exit;
            end if;
            X := X + 1;
         end loop;

         if Count = 0 then
            return Smallest_Prime_Factor (N);
         end if;

         declare
            Rels : Relation_List (1 .. Count);
         begin
            for I in 1 .. Count loop
               Rels (I) := Buf (I);
            end loop;
            Factor :=
              Factor_Via_Congruence_Of_Squares (N, Rels, Base);
            if Factor > 1 and then Factor < N then
               return Factor;
            end if;
         end;

         --  Fallback: still educational — peel by trial.
         return Smallest_Prime_Factor (N);
      end;
   end Toy_Factor_SNFS_Like;

end Special_Number_Field_Sieve;
