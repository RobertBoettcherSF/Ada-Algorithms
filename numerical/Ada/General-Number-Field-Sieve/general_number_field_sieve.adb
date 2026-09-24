--  General Number Field Sieve — Ada 2023 body (educational toy).

pragma Ada_2022;

with Interfaces;

package body General_Number_Field_Sieve
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy / complexity names
   ------------------------------------------------------------------

   function Family_Name (F : Factoring_Family) return String is
   begin
      case F is
         when Trial_Division =>
            return "Trial division";
         when Quadratic_Sieve =>
            return "Quadratic sieve";
         when Special_NFS =>
            return "Special number field sieve (SNFS)";
         when General_NFS =>
            return "General number field sieve (GNFS)";
         when ECM_Like =>
            return "Elliptic curve method (ECM)";
         when Other =>
            return "Other / unclassified";
      end case;
   end Family_Name;

   function Heuristic_Complexity (F : Factoring_Family) return String is
   begin
      case F is
         when Trial_Division =>
            return "O(sqrt(n))";
         when Quadratic_Sieve =>
            return "L_n[1/2,1]";
         when Special_NFS =>
            return "L_n[1/3,(32/9)^{1/3}]";
         when General_NFS =>
            return "L_n[1/3,(64/9)^{1/3}]";
         when ECM_Like =>
            return "L_p[1/2,sqrt(2)]";
         when Other =>
            return "(unspecified)";
      end case;
   end Heuristic_Complexity;

   function Is_L_One_Third_Family (F : Factoring_Family) return Boolean is
   begin
      return F = Special_NFS or else F = General_NFS;
   end Is_L_One_Third_Family;

   ------------------------------------------------------------------
   --  SNFS vs GNFS
   ------------------------------------------------------------------

   function Variant_Name (V : Nfs_Variant) return String is
   begin
      case V is
         when General_Nfs =>
            return "GNFS (general)";
         when Special_Nfs =>
            return "SNFS (special form)";
      end case;
   end Variant_Name;

   function Complexity_Constant_Numerator (V : Nfs_Variant) return Natural is
   begin
      case V is
         when General_Nfs =>
            return 64;
         when Special_Nfs =>
            return 32;
      end case;
   end Complexity_Constant_Numerator;

   function Prefer_Snfs_When_Special_Form return Boolean is
   begin
      return True;
   end Prefer_Snfs_When_Special_Form;

   function Recommended_Variant
     (Bit_Length       : Natural;
      Has_Special_Form : Boolean) return Nfs_Variant
   is
   begin
      if Bit_Length < 2 then
         raise Invalid_Argument;
      end if;
      if Has_Special_Form and then Prefer_Snfs_When_Special_Form then
         return Special_Nfs;
      end if;
      return General_Nfs;
   end Recommended_Variant;

   ------------------------------------------------------------------
   --  Pipeline stages
   ------------------------------------------------------------------

   function Stage_Name (S : Pipeline_Stage) return String is
   begin
      case S is
         when Polynomial_Selection =>
            return "Polynomial selection";
         when Factor_Base_Setup =>
            return "Factor-base setup";
         when Sieving =>
            return "Sieving (rational + algebraic)";
         when Filtering =>
            return "Filtering / singleton removal";
         when Linear_Algebra =>
            return "Linear algebra over GF(2)";
         when Square_Root =>
            return "Square root (rational + algebraic)";
         when Gcd_Split =>
            return "GCD split gcd(|X-Y|, N)";
      end case;
   end Stage_Name;

   function First_Stage return Pipeline_Stage is
   begin
      return Pipeline_Stage'First;
   end First_Stage;

   function Last_Stage return Pipeline_Stage is
   begin
      return Pipeline_Stage'Last;
   end Last_Stage;

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
   --  Factor base / smoothness
   ------------------------------------------------------------------

   function Primes_Up_To (B : U64) return Factor_Base is
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

   Max_FB : constant := 64;

   type Bit_Row is array (1 .. Max_FB) of Boolean;
   type Bit_Matrix is array (Positive range <>) of Bit_Row;
   type Bool_Vec is array (Positive range <>) of Boolean;

   procedure Find_Dependency
     (Parity     : Bit_Matrix;
      Cols       : Natural;
      Rows       : Natural;
      Found      : out Boolean;
      Combo      : out Bit_Row)
   is
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

         declare
            Active  : Bool_Vec (1 .. Rows) := [others => True];
            Attempt : Natural := 0;
         begin
            while Attempt < Rows loop
               Attempt := Attempt + 1;
               declare
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

                  declare
                     Use_Orig : Bit_Row := [others => False];
                     Left     : U64 := 1;
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

                     for J in Base'Range loop
                        if (Total_E (J) rem 2) /= 0 then
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
   --  Toy_Factor
   ------------------------------------------------------------------

   function Toy_Factor
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
         return 0;
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if Is_Prime_Trial (N) then
         return 0;
      end if;

      declare
         B         : constant U64 :=
           (if Smoothness < 3 then 3 else Smoothness);
         Base      : constant Factor_Base := Primes_Up_To (B);
         Need      : constant Natural :=
           Natural'Min (Max_FB, Base'Length + 5);
         Root      : constant U64 := Floor_Sqrt (N);
         Start_X   : constant U64 := Root + 1;
         Buf       : array (1 .. Max_FB) of Relation;
         Count     : Natural := 0;
         X         : U64 := Start_X;
         Scan_Max  : constant U64 :=
           (if N > 500_000 then N else N * 2);
         Iters     : Natural := 0;
         Max_Iters : constant Natural := 200_000;
         Factor    : U64;
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

         return Smallest_Prime_Factor (N);
      end;
   end Toy_Factor;

end General_Number_Field_Sieve;
