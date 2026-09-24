--  Index calculus algorithm — Ada 2023 body (educational toy).

pragma Ada_2022;

with Interfaces;

package body Index_Calculus
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Mul_Mod / Mod_Pow / Gcd / Sub_Mod / Modular_Inverse / Floor_Sqrt
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

   function Sub_Mod (X, Y, M : U64) return U64 is
      XX, YY : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX := X rem M;
      YY := Y rem M;
      if XX >= YY then
         return XX - YY;
      else
         return XX + M - YY;
      end if;
   end Sub_Mod;

   --  Extended Euclidean on Long_Long_Integer; returns (G, X, Y) with
   --  A*X + B*Y = G and G ≥ 0.
   procedure Extended_Gcd_LL
     (A, B       : Long_Long_Integer;
      G, X, Y    : out Long_Long_Integer)
   is
      Old_R, R          : Long_Long_Integer;
      Old_S, S          : Long_Long_Integer;
      Old_T, T          : Long_Long_Integer;
      Quotient, Tmp     : Long_Long_Integer;
   begin
      Old_R := A;
      R     := B;
      Old_S := 1;
      S     := 0;
      Old_T := 0;
      T     := 1;
      while R /= 0 loop
         Quotient := Old_R / R;
         Tmp := R;
         R := Old_R - Quotient * R;
         Old_R := Tmp;
         Tmp := S;
         S := Old_S - Quotient * S;
         Old_S := Tmp;
         Tmp := T;
         T := Old_T - Quotient * T;
         Old_T := Tmp;
      end loop;
      if Old_R < 0 then
         G := -Old_R;
         X := -Old_S;
         Y := -Old_T;
      else
         G := Old_R;
         X := Old_S;
         Y := Old_T;
      end if;
   end Extended_Gcd_LL;

   function Modular_Inverse (A, M : U64) return U64 is
      AA, MM    : Long_Long_Integer;
      G, X, Y   : Long_Long_Integer;
      Inv       : Long_Long_Integer;
   begin
      if M <= 1 then
         raise Invalid_Argument;
      end if;
      AA := Long_Long_Integer (A rem M);
      MM := Long_Long_Integer (M);
      Extended_Gcd_LL (AA, MM, G, X, Y);
      pragma Unreferenced (Y);
      if G /= 1 then
         raise Invalid_Argument;
      end if;
      Inv := X mod MM;
      if Inv < 0 then
         Inv := Inv + MM;
      end if;
      return U64 (Inv);
   end Modular_Inverse;

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

   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
   is
   begin
      if Modulus <= 1 then
         return False;
      end if;
      return Mod_Pow (Alpha, Log, Modulus) = (Beta rem Modulus);
   end Verify_Discrete_Log;

   ------------------------------------------------------------------
   --  Factor base / smoothness
   ------------------------------------------------------------------

   function Primes_Up_To (B : U64) return Factor_Base is
      Buf   : array (1 .. Max_Factor_Base) of U64;
      Count : Natural := 0;
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
            exit when Count = Max_Factor_Base;
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
   --  Tiny LCG for reproducible "random" exponents k
   ------------------------------------------------------------------

   function Next_LCG (State : in out U64) return U64 is
   begin
      --  Numerical Recipes LCG (mod 2^64 via U64 wrap).
      State := State * 1_664_525 + 1_013_904_223;
      return State;
   end Next_LCG;

   ------------------------------------------------------------------
   --  Collect_Relations
   ------------------------------------------------------------------

   function Collect_Relations
     (Generator : U64;
      Modulus   : U64;
      Order     : U64;
      Base      : Factor_Base;
      Seed      : U64     := 1;
      Max_Tries : Natural := 10_000) return Relation_List
   is
      Need  : constant Natural :=
        Natural'Min (Max_Relations,
                     Base'Length * 3 + 8);
      Buf   : array (1 .. Max_Relations) of Relation;
      Count : Natural := 0;
      State : U64 := Seed;
      K     : U64;
      Val   : U64;
      G     : constant U64 := Generator rem Modulus;
   begin
      if Modulus < 2 or else Order = 0 then
         raise Invalid_Argument;
      end if;
      if Base'Length = 0 or else Base'Length > Max_Factor_Base then
         raise Invalid_Argument;
      end if;
      if G = 0 then
         raise Invalid_Argument;
      end if;

      --  Pass 1: sequential k (dense classroom hits); Pass 2: seeded LCG.
      for Pass in 1 .. 2 loop
         declare
            Sequential : constant Boolean := Pass = 1;
         begin
         for Try in 1 .. Max_Tries loop
            if not Sequential then
               K := Next_LCG (State) rem Order;
               if K = 0 then
                  K := 1;
               end if;
            else
               K := U64 (Try) rem Order;
               if K = 0 then
                  K := Order;
               end if;
            end if;

            Val := Mod_Pow (G, K, Modulus);
            if Val /= 0 and then Is_B_Smooth (Val, Base) then
               declare
                  E     : constant Exponent_Vector :=
                    Smooth_Exponents (Val, Base);
                  All_Z : Boolean := True;
                  Dup   : Boolean := False;
                  Rel   : Relation;
               begin
                  for X of E loop
                     if X /= 0 then
                        All_Z := False;
                        exit;
                     end if;
                  end loop;

                  if not All_Z then
                     Rel.K := K rem Order;
                     Rel.Width := Base'Length;
                     for I in Base'Range loop
                        Rel.Exponents (I - Base'First + 1) := E (I);
                     end loop;

                     for J in 1 .. Count loop
                        Dup := True;
                        for C in 1 .. Base'Length loop
                           if Buf (J).Exponents (C) /= Rel.Exponents (C) then
                              Dup := False;
                              exit;
                           end if;
                        end loop;
                        exit when Dup;
                     end loop;

                     if not Dup then
                        if Count < Max_Relations then
                           Count := Count + 1;
                           Buf (Count) := Rel;
                        end if;
                     end if;
                  end if;
               end;
            end if;

            exit when Count >= Need;
         end loop;
         end;
         exit when Count >= Base'Length;
      end loop;

      declare
         Result : Relation_List (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Buf (I);
         end loop;
         return Result;
      end;
   end Collect_Relations;

   ------------------------------------------------------------------
   --  Solve_Factor_Base_Logs — Gaussian elimination mod Order
   ------------------------------------------------------------------

   function Solve_Factor_Base_Logs
     (Generator : U64;
      Modulus   : U64;
      Order     : U64;
      Base      : Factor_Base;
      Relations : Relation_List) return Log_Vector
   is
      N : constant Natural := Base'Length;
      R : constant Natural := Relations'Length;
      Empty : Log_Vector (1 .. 0);
   begin
      if Modulus < 2 or else Order = 0 then
         raise Invalid_Argument;
      end if;
      if N = 0 or else N > Max_Factor_Base then
         raise Invalid_Argument;
      end if;
      if R = 0 or else R < N then
         return Empty;
      end if;

      for Rel of Relations loop
         if Rel.Width /= N then
            raise Invalid_Argument;
         end if;
      end loop;

      declare
         --  Augmented matrix A(row, 1..N | N+1) with entries in 0 .. Order-1.
         --  Row indices 1 .. R_Use.
         R_Use : constant Natural := Natural'Min (R, Max_Relations);
         type Row_Array is array (1 .. Max_Factor_Base + 1) of U64;
         type Mat_Array is array (1 .. Max_Relations) of Row_Array;
         A       : Mat_Array := [others => [others => 0]];
         Pivots  : array (1 .. Max_Factor_Base) of Integer := [others => -1];
         Row     : Natural := 1;
         Pivot   : Natural;
         Found   : Boolean;
         Inv_P   : U64;
         Factor  : U64;
         Sol     : Log_Vector (1 .. N);
         G_Gen   : constant U64 := Generator rem Modulus;
      begin
         for I in 1 .. R_Use loop
            declare
               Rel : Relation renames Relations (Relations'First + I - 1);
            begin
               for C in 1 .. N loop
                  A (I)(C) := U64 (Rel.Exponents (C)) rem Order;
               end loop;
               A (I)(N + 1) := Rel.K rem Order;
            end;
         end loop;

         --  Forward elimination: prefer invertible pivots (gcd = 1).
         --  When Order is composite, non-invertible columns are skipped;
         --  free variables are treated as failure unless every column
         --  obtains an invertible pivot (classroom full-rank demand).
         for C in 1 .. N loop
            Found := False;
            Pivot := Row;
            for I in Row .. R_Use loop
               if A (I)(C) rem Order /= 0
                 and then Gcd (A (I)(C) rem Order, Order) = 1
               then
                  Pivot := I;
                  Found := True;
                  exit;
               end if;
            end loop;

            if not Found then
               return Empty;
            end if;

            if Pivot /= Row then
               declare
                  Tmp : constant Row_Array := A (Row);
               begin
                  A (Row) := A (Pivot);
                  A (Pivot) := Tmp;
               end;
            end if;

            begin
               Inv_P := Modular_Inverse (A (Row)(C) rem Order, Order);
            exception
               when Invalid_Argument =>
                  return Empty;
            end;

            for J in 1 .. N + 1 loop
               A (Row)(J) := Mul_Mod (A (Row)(J), Inv_P, Order);
            end loop;

            for I in 1 .. R_Use loop
               if I /= Row then
                  Factor := A (I)(C) rem Order;
                  if Factor /= 0 then
                     for J in 1 .. N + 1 loop
                        A (I)(J) :=
                          Sub_Mod
                            (A (I)(J),
                             Mul_Mod (Factor, A (Row)(J), Order),
                             Order);
                     end loop;
                  end if;
               end if;
            end loop;

            Pivots (C) := Integer (Row);
            Row := Row + 1;
            exit when Row > R_Use;
         end loop;

         for C in 1 .. N loop
            if Pivots (C) < 0 then
               return Empty;
            end if;
            Sol (C) := A (Pivots (C))(N + 1) rem Order;
         end loop;

         --  Verify Generator^Sol(i) ≡ Base(i) (mod Modulus).
         for I in 1 .. N loop
            if Mod_Pow (G_Gen, Sol (I), Modulus) /= (Base (Base'First + I - 1)
                                                       rem Modulus)
            then
               return Empty;
            end if;
         end loop;

         return Sol;
      end;
   end Solve_Factor_Base_Logs;

   ------------------------------------------------------------------
   --  Individual logarithm descent
   ------------------------------------------------------------------

   function Individual_Logarithm
     (Alpha, Beta, Modulus, Order : U64;
      Base                        : Factor_Base;
      Base_Logs                   : Log_Vector;
      Seed                        : U64) return U64
   is
      State : U64 := Seed xor 16#A5A5_A5A5_A5A5_A5A5#;
      S     : U64;
      Val   : U64;
      Gamma : U64;
      Max_S : constant Natural :=
        Natural (U64'Min (Order * 5 + 100, U64 (200_000)));
      Brem  : constant U64 := Beta rem Modulus;
      Arem  : constant U64 := Alpha rem Modulus;
      Found : Boolean := False;
   begin
      if Base'Length /= Base_Logs'Length then
         return Order;
      end if;

      --  Pass 1: sequential k (dense classroom hits); Pass 2: seeded LCG.
      for Pass in 1 .. 2 loop
         declare
            Sequential : constant Boolean := Pass = 1;
         begin
         for Try in 0 .. Max_S loop
            if Sequential then
               S := U64 (Try) rem Order;
            else
               S := Next_LCG (State) rem Order;
            end if;

            Val := Mul_Mod (Brem, Mod_Pow (Arem, S, Modulus), Modulus);
            if Val /= 0 and then Is_B_Smooth (Val, Base) then
               declare
                  E : constant Exponent_Vector :=
                    Smooth_Exponents (Val, Base);
               begin
                  Gamma := Sub_Mod (0, S, Order);
                  for I in Base'Range loop
                     declare
                        Idx : constant Positive :=
                          I - Base'First + Base_Logs'First;
                        Ei  : constant Natural := E (I);
                     begin
                        if Ei > 0 then
                           Gamma :=
                             (Gamma
                              + Mul_Mod
                                  (U64 (Ei),
                                   Base_Logs (Idx) rem Order,
                                   Order))
                             rem Order;
                        end if;
                     end;
                  end loop;

                  if Verify_Discrete_Log (Arem, Brem, Modulus, Gamma) then
                     Found := True;
                  end if;
               end;
            end if;

            if Found then
               return Gamma;
            end if;
         end loop;
         end;
         exit when Found;
      end loop;

      return Order;
   end Individual_Logarithm;

   ------------------------------------------------------------------
   --  Discrete_Log_Index_Calculus
   ------------------------------------------------------------------

   function Try_With_Bound
     (A, B, Modulus, Order, Bound, Seed : U64) return U64
   is
      Raw   : constant Factor_Base := Primes_Up_To (Bound);
      Count : Natural := 0;
      Tmp   : array (1 .. Max_Factor_Base) of U64;
   begin
      for P of Raw loop
         if P < Modulus then
            Count := Count + 1;
            Tmp (Count) := P;
            exit when Count = Max_Factor_Base;
         end if;
      end loop;

      if Count = 0 then
         return Order;
      end if;

      declare
         Base  : Factor_Base (1 .. Count);
         Gamma : U64;
      begin
         for I in 1 .. Count loop
            Base (I) := Tmp (I);
         end loop;

         declare
            Collected : constant Relation_List :=
              Collect_Relations
                (Generator => A,
                 Modulus   => Modulus,
                 Order     => Order,
                 Base      => Base,
                 Seed      => Seed,
                 Max_Tries => 20_000);
            Solved : constant Log_Vector :=
              Solve_Factor_Base_Logs
                (Generator => A,
                 Modulus   => Modulus,
                 Order     => Order,
                 Base      => Base,
                 Relations => Collected);
         begin
            if Solved'Length = Base'Length then
               Gamma :=
                 Individual_Logarithm
                   (A, B, Modulus, Order, Base, Solved, Seed);
               return Gamma;
            end if;
         end;

         return Order;
      end;
   end Try_With_Bound;

   function Discrete_Log_Index_Calculus
     (Alpha      : U64;
      Beta       : U64;
      Modulus    : U64;
      Order      : U64;
      Smoothness : U64 := 20;
      Seed       : U64 := 1) return U64
   is
      A : U64;
      B : U64;
      Gamma : U64;
      Bounds : constant array (Positive range <>) of U64 :=
        [Smoothness,
         Smoothness + 10,
         Smoothness + 20,
         50,
         100,
         200];
      Prev : U64 := 0;
   begin
      if Modulus < 2 or else Modulus > Max_Educational_Modulus then
         raise Invalid_Argument;
      end if;
      if Order = 0 then
         raise Invalid_Argument;
      end if;

      A := Alpha rem Modulus;
      B := Beta rem Modulus;
      if A = 0 or else B = 0 then
         raise Invalid_Argument;
      end if;

      --  Trivial targets.
      if B = 1 then
         return 0;
      end if;
      if B = A then
         return 1 rem Order;
      end if;

      for Bi in Bounds'Range loop
         declare
            Bound : U64 := Bounds (Bi);
         begin
            if Bound < 2 then
               Bound := 2;
            end if;
            if Bound /= Prev then
               Prev := Bound;
               Gamma := Try_With_Bound (A, B, Modulus, Order, Bound, Seed);
               if Gamma < Order then
                  return Gamma;
               end if;
            end if;
         end;
      end loop;

      return Order;
   end Discrete_Log_Index_Calculus;

end Index_Calculus;
