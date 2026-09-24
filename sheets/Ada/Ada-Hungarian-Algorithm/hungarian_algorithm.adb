--  Hungarian_Algorithm body — dual O(n³) Kuhn–Munkres + brute oracle.

pragma Ada_2022;

package body Hungarian_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Problem mutators / inspectors
   ---------------------------------------------------------------------------

   procedure Clear (P : in out Problem; Size : Natural) is
   begin
      if Size > Max_N then
         raise Invalid_Argument;
      end if;
      P.N := Size;
      for I in Index loop
         for J in Index loop
            P.Costs (I, J) := 0;
         end loop;
      end loop;
   end Clear;

   procedure Set_Cost
     (P : in out Problem; Row, Col : Index; Cost : Integer)
   is
   begin
      if Natural (Row) > P.N or else Natural (Col) > P.N then
         raise Invalid_Argument;
      end if;
      P.Costs (Row, Col) := Cost_Value (Cost);
   end Set_Cost;

   procedure Load_Matrix (P : in out Problem; Costs : Cost_Matrix) is
      R : constant Natural := Costs'Length (1);
      K : constant Natural := Costs'Length (2);
   begin
      if Costs'First (1) /= 1
        or else Costs'First (2) /= 1
        or else R /= K
        or else R > Max_N
      then
         raise Invalid_Argument;
      end if;
      Clear (P, R);
      for I in 1 .. R loop
         for J in 1 .. R loop
            P.Costs (Index (I), Index (J)) := Costs (I, J);
         end loop;
      end loop;
   end Load_Matrix;

   function Size (P : Problem) return Natural is
   begin
      return P.N;
   end Size;

   function Get_Cost
     (P : Problem; Row, Col : Index) return Cost_Value
   is
   begin
      if Natural (Row) > P.N or else Natural (Col) > P.N then
         raise Invalid_Argument;
      end if;
      return P.Costs (Row, Col);
   end Get_Cost;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Is_Permutation
     (A : Assignment_Array; N : Natural) return Boolean
   is
      Seen : array (1 .. Max_N) of Boolean := [others => False];
   begin
      if N = 0 then
         return True;
      end if;
      if A'First /= 1 or else A'Length < N then
         return False;
      end if;
      for I in 1 .. N loop
         declare
            J : constant Natural := A (I);
         begin
            if J < 1 or else J > N or else Seen (J) then
               return False;
            end if;
            Seen (J) := True;
         end;
      end loop;
      return True;
   end Is_Permutation;

   function Assignment_Cost
     (P : Problem; A : Assignment_Array) return Cost_Value
   is
      Sum : Cost_Value := 0;
   begin
      if not Is_Permutation (A, P.N) then
         raise Invalid_Argument;
      end if;
      for I in 1 .. P.N loop
         Sum := Sum + P.Costs (Index (I), Index (A (I)));
      end loop;
      return Sum;
   end Assignment_Cost;

   ---------------------------------------------------------------------------
   -- Core O(n³) dual Kuhn–Munkres (minimize)
   --
   -- Maintains row potentials U and column potentials V such that
   --   C(i,j) − U(i) − V(j) ≥ 0  for all i, j
   -- and grows a matching of tight edges (reduced cost 0) until it is
   -- perfect. Each of the n augmentations costs O(n²), hence O(n³).
   ---------------------------------------------------------------------------

   procedure Solve_Minimize (P : Problem; Result : out Solution) is
      N : constant Natural := P.N;
   begin
      Result.N := N;
      Result.Total_Cost := 0;
      Result.Assignment := [others => 0];

      if N = 0 then
         return;
      end if;

      declare
         A : array (1 .. N, 1 .. N) of Cost_Value;
         U : array (0 .. N) of Cost_Value := [others => 0];
         V : array (0 .. N) of Cost_Value := [others => 0];
         --  Pmatch (J) = row matched to column J; Pmatch (0) is the
         --  free row of the current phase.
         Pmatch : array (0 .. N) of Natural := [others => 0];
         Way    : array (1 .. N) of Natural := [others => 0];
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               A (I, J) := P.Costs (Index (I), Index (J));
            end loop;
         end loop;

         for I in 1 .. N loop
            Pmatch (0) := I;
            declare
               J0   : Natural := 0;
               Minv : array (1 .. N) of Cost_Value :=
                 [others => Large_Cost];
               Used : array (0 .. N) of Boolean := [others => False];
            begin
               loop
                  Used (J0) := True;
                  declare
                     I0  : constant Natural := Pmatch (J0);
                     Dlt : Cost_Value := Large_Cost;
                     J1  : Natural := 0;
                  begin
                     for J in 1 .. N loop
                        if not Used (J) then
                           declare
                              Cur : constant Cost_Value :=
                                A (I0, J) - U (I0) - V (J);
                           begin
                              if Cur < Minv (J) then
                                 Minv (J) := Cur;
                                 Way (J)  := J0;
                              end if;
                              if Minv (J) < Dlt then
                                 Dlt := Minv (J);
                                 J1  := J;
                              end if;
                           end;
                        end if;
                     end loop;

                     for J in 0 .. N loop
                        if Used (J) then
                           U (Pmatch (J)) := U (Pmatch (J)) + Dlt;
                           V (J)          := V (J) - Dlt;
                        elsif J >= 1 then
                           Minv (J) := Minv (J) - Dlt;
                        end if;
                     end loop;

                     J0 := J1;
                  end;
                  exit when Pmatch (J0) = 0;
               end loop;

               declare
                  Cur_J : Natural := J0;
                  Prev  : Natural;
               begin
                  loop
                     Prev         := Way (Cur_J);
                     Pmatch (Cur_J) := Pmatch (Prev);
                     Cur_J        := Prev;
                     exit when Cur_J = 0;
                  end loop;
               end;
            end;
         end loop;

         for J in 1 .. N loop
            if Pmatch (J) /= 0 then
               Result.Assignment (Pmatch (J)) := J;
            end if;
         end loop;

         Result.Total_Cost := 0;
         for I in 1 .. N loop
            Result.Total_Cost :=
              Result.Total_Cost + A (I, Result.Assignment (I));
         end loop;
      end;
   end Solve_Minimize;

   procedure Solve_Maximize (P : Problem; Result : out Solution) is
      Neg : Problem;
   begin
      Clear (Neg, P.N);
      for I in 1 .. P.N loop
         for J in 1 .. P.N loop
            Neg.Costs (Index (I), Index (J)) :=
              -P.Costs (Index (I), Index (J));
         end loop;
      end loop;
      Solve_Minimize (Neg, Result);
      Result.Total_Cost := -Result.Total_Cost;
   end Solve_Maximize;

   ---------------------------------------------------------------------------
   -- Brute-force permutation enumeration
   ---------------------------------------------------------------------------

   procedure Brute
     (P       : Problem;
      Want_Max : Boolean;
      Result  : out Solution)
   is
      N : constant Natural := P.N;
      Best_Cost : Cost_Value;
      Best_Asg  : Assignment_Array (1 .. Max_N) := [others => 0];
      Cur       : Assignment_Array (1 .. Max_N) := [others => 0];
      Used      : array (1 .. Max_N) of Boolean := [others => False];
      First     : Boolean := True;

      procedure Recurse (Depth : Natural) is
         Sum : Cost_Value;
      begin
         if Depth > N then
            Sum := 0;
            for I in 1 .. N loop
               Sum := Sum + P.Costs (Index (I), Index (Cur (I)));
            end loop;
            if First
              or else (Want_Max and then Sum > Best_Cost)
              or else ((not Want_Max) and then Sum < Best_Cost)
            then
               First := False;
               Best_Cost := Sum;
               for I in 1 .. N loop
                  Best_Asg (I) := Cur (I);
               end loop;
            end if;
            return;
         end if;
         for J in 1 .. N loop
            if not Used (J) then
               Used (J) := True;
               Cur (Depth) := J;
               Recurse (Depth + 1);
               Used (J) := False;
            end if;
         end loop;
      end Recurse;
   begin
      if N > Max_Brute_N then
         raise Invalid_Argument;
      end if;

      Result.N := N;
      Result.Total_Cost := 0;
      Result.Assignment := [others => 0];

      if N = 0 then
         return;
      end if;

      Best_Cost := 0;
      Recurse (1);
      Result.Total_Cost := Best_Cost;
      for I in 1 .. N loop
         Result.Assignment (I) := Best_Asg (I);
      end loop;
   end Brute;

   procedure Solve_Brute_Minimize (P : Problem; Result : out Solution) is
   begin
      Brute (P, Want_Max => False, Result => Result);
   end Solve_Brute_Minimize;

   procedure Solve_Brute_Maximize (P : Problem; Result : out Solution) is
   begin
      Brute (P, Want_Max => True, Result => Result);
   end Solve_Brute_Maximize;

end Hungarian_Algorithm;
