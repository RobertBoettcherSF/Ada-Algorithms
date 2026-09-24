--  Hungarian_Method body — dual O(n³) Kuhn–Munkres (educational).

pragma Ada_2022;

package body Hungarian_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Square (C : Cost_Matrix) return Boolean is
   begin
      return C'Length (1) = C'Length (2);
   end Is_Square;

   function Is_Permutation
     (A : Assignment; N : Dimension) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return True;
      end if;
      if A'Length < N then
         return False;
      end if;
      for K in 0 .. N - 1 loop
         declare
            J : constant Natural := A (A'First + K);
         begin
            if J < 1 or else J > Natural (N) then
               return False;
            end if;
            if Seen (J) then
               return False;
            end if;
            Seen (J) := True;
         end;
      end loop;
      return True;
   end Is_Permutation;

   function Assignment_Cost
     (C : Cost_Matrix; A : Assignment) return Cost
   is
      N    : constant Dimension := C'Length (1);
      Sum  : Cost := 0;
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return 0;
      end if;
      if A'First /= C'First (1) or else A'Last /= C'Last (1) then
         raise Invalid_Argument;
      end if;
      for I in C'Range (1) loop
         declare
            J : constant Natural := A (I);
         begin
            if J < Natural (C'First (2))
              or else J > Natural (C'Last (2))
            then
               raise Invalid_Argument;
            end if;
            declare
               Local : constant Positive :=
                 Positive (Integer (J) - Integer (C'First (2)) + 1);
            begin
               if Local > Positive (N) or else Seen (Local) then
                  raise Invalid_Argument;
               end if;
               Seen (Local) := True;
            end;
            Sum := Sum + C (I, J);
         end;
      end loop;
      return Sum;
   end Assignment_Cost;

   function Pad_To_Square
     (C    : Cost_Matrix;
      Fill : Cost := 0) return Cost_Matrix
   is
      R : constant Natural := C'Length (1);
      K : constant Natural := C'Length (2);
      N : constant Natural := Natural'Max (R, K);
   begin
      if N = 0 then
         declare
            Empty : Cost_Matrix (1 .. 0, 1 .. 0);
         begin
            return Empty;
         end;
      end if;
      declare
         P : Cost_Matrix (1 .. N, 1 .. N) :=
           [others => [others => Fill]];
      begin
         for I in 1 .. R loop
            for J in 1 .. K loop
               P (I, J) :=
                 C (C'First (1) + (I - 1), C'First (2) + (J - 1));
            end loop;
         end loop;
         return P;
      end;
   end Pad_To_Square;

   function Negate (C : Cost_Matrix) return Cost_Matrix is
      Out_M : Cost_Matrix (C'Range (1), C'Range (2));
   begin
      for I in C'Range (1) loop
         for J in C'Range (2) loop
            Out_M (I, J) := -C (I, J);
         end loop;
      end loop;
      return Out_M;
   end Negate;

   ---------------------------------------------------------------------------
   -- Core O(n³) dual Kuhn–Munkres
   --
   -- Maintains row potentials U and column potentials V such that
   --   C(i,j) − U(i) − V(j) ≥ 0  for all i, j
   -- and grows a matching of tight edges (reduced cost 0) until it is
   -- perfect. Each of the n augmentations costs O(n²), hence O(n³).
   ---------------------------------------------------------------------------

   function Minimize_Assignment (C : Cost_Matrix) return Result is
      N : constant Dimension := C'Length (1);
      R : Result;
   begin
      R.N := N;
      if N = 0 then
         R.Success := True;
         R.Total   := 0;
         return R;
      end if;

      declare
         A : array (1 .. N, 1 .. N) of Cost;
         U : array (0 .. N) of Cost := [others => 0];
         V : array (0 .. N) of Cost := [others => 0];
         --  P (J) = row matched to column J; P (0) is the free row of
         --  the current phase.
         P   : array (0 .. N) of Natural := [others => 0];
         Way : array (1 .. N) of Natural := [others => 0];
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               A (I, J) :=
                 C (C'First (1) + (I - 1), C'First (2) + (J - 1));
            end loop;
         end loop;

         for I in 1 .. N loop
            P (0) := I;
            declare
               J0   : Natural := 0;
               Minv : array (1 .. N) of Cost := [others => Large_Cost];
               Used : array (0 .. N) of Boolean := [others => False];
            begin
               loop
                  Used (J0) := True;
                  declare
                     I0    : constant Natural := P (J0);
                     Dlt : Cost := Large_Cost;
                     J1    : Natural := 0;
                  begin
                     for J in 1 .. N loop
                        if not Used (J) then
                           declare
                              Cur : constant Cost :=
                                A (I0, J) - U (I0) - V (J);
                           begin
                              if Cur < Minv (J) then
                                 Minv (J) := Cur;
                                 Way (J)  := J0;
                              end if;
                              if Minv (J) < Dlt then
                                 Dlt := Minv (J);
                                 J1    := J;
                              end if;
                           end;
                        end if;
                     end loop;

                     for J in 0 .. N loop
                        if Used (J) then
                           U (P (J)) := U (P (J)) + Dlt;
                           V (J)     := V (J) - Dlt;
                        elsif J >= 1 then
                           Minv (J) := Minv (J) - Dlt;
                        end if;
                     end loop;

                     J0 := J1;
                  end;
                  exit when P (J0) = 0;
               end loop;

               declare
                  Cur_J : Natural := J0;
                  Prev  : Natural;
               begin
                  loop
                     Prev      := Way (Cur_J);
                     P (Cur_J) := P (Prev);
                     Cur_J     := Prev;
                     exit when Cur_J = 0;
                  end loop;
               end;
            end;
         end loop;

         for J in 1 .. N loop
            if P (J) /= 0 then
               R.Mapping (P (J)) := J;
            end if;
         end loop;

         R.Total := 0;
         for I in 1 .. N loop
            R.Total := R.Total + A (I, R.Mapping (I));
         end loop;
         R.Success := True;
      end;

      return R;
   end Minimize_Assignment;

   function Maximize_Assignment (C : Cost_Matrix) return Result is
      Neg : constant Cost_Matrix := Negate (C);
      R   : Result := Minimize_Assignment (Neg);
   begin
      R.Total := -R.Total;
      return R;
   end Maximize_Assignment;

end Hungarian_Method;
