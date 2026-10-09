pragma Ada_2022;

package body Lemke_Howson with SPARK_Mode => On is

   --  A tableau: rows are the constraints of one polytope, column 0 the
   --  right-hand side, column L the variable with label L.  The entries
   --  are the true tableau times Det (fraction-free pivoting), so each row
   --  of the basic variables' columns stays Det times the identity.
   subtype Column is Natural range 0 .. 2 * Max_Strategies;
   type Tableau is array (Strategy_Count range <>, Column range <>) of Big_Integer;
   type Basis_List is array (Strategy_Count range <>) of Label_Type;

   --  T (R1, C) and T (R2, C) are positive.  True when row R1's ratio
   --  vector (T (R1, 0), T (R1, slack columns)) / T (R1, C) is
   --  lexicographically smaller than row R2's.  Slack columns are labels
   --  From .. To (they formed the starting basis).  The denominators are
   --  positive, so the comparison is by cross-multiplication.
   function Lex_Less (T : Tableau; R1, R2 : Strategy_Count; C : Column; From, To : Column) return Boolean
   with
     Global => null,
     Pre    => R1 in T'Range (1) and then R2 in T'Range (1) and then C in T'Range (2)
               and then From in T'Range (2) and then To in T'Range (2)
               and then T'First (2) = 0
   is
   begin
      if T (R1, 0) * T (R2, C) /= T (R2, 0) * T (R1, C) then
         return T (R1, 0) * T (R2, C) < T (R2, 0) * T (R1, C);
      end if;
      for K in From .. To loop
         if T (R1, K) * T (R2, C) /= T (R2, K) * T (R1, C) then
            return T (R1, K) * T (R2, C) < T (R2, K) * T (R1, C);
         end if;
      end loop;
      return False;
   end Lex_Less;

   --  Brings the variable with label C into the basis of T.  Leaving is
   --  the label of the variable that leaves; Ok is False when column C has
   --  no positive entry (cannot happen for these polytopes, which are
   --  bounded; reported rather than assumed).
   procedure Pivot
     (T        : in out Tableau;
      Basis    : in out Basis_List;
      Det      : in out Big_Integer;
      C        : Label_Type;
      From, To : Column;
      Leaving  : out Label_Type;
      Ok       : out Boolean)
   with
     Global => null,
     Pre    => T'First (2) = 0 and then C in T'Range (2) and then From in T'Range (2)
               and then To in T'Range (2) and then Basis'First = T'First (1)
               and then Basis'Last = T'Last (1) and then Det > 0
               and then (for all R in Basis'Range => Basis (R) <= T'Last (2)),
     Post   => Det > 0 and then Leaving <= T'Last (2)
               and then (for all R in Basis'Range => Basis (R) <= T'Last (2))
   is
      R     : Natural := 0;
      Pivot_Entry : Big_Integer;
      --  Row I's entry in column C before row I is updated.
      F           : Big_Integer;
   begin
      Leaving := C;
      for I in T'Range (1) loop
         if T (I, C) > 0 and then (R not in T'Range (1) or else Lex_Less (T, I, R, C, From, To)) then
            R := I;
         end if;
         pragma Loop_Invariant (R = 0 or else (R in T'Range (1) and then T (R, C) > 0));
      end loop;
      if R not in T'Range (1) then
         Ok := False;
         return;
      end if;
      Pivot_Entry := T (R, C);
      for I in T'Range (1) loop
         if I /= R then
            F := T (I, C);
            for K in T'Range (2) loop
               T (I, K) := (Pivot_Entry * T (I, K) - F * T (R, K)) / Det;
            end loop;
         end if;
         pragma Loop_Invariant (T (R, C) = Pivot_Entry);
      end loop;
      Det := Pivot_Entry;
      Leaving := Basis (R);
      Basis (R) := C;
      Ok := True;
   end Pivot;

   --  Numerators of the basic variables with labels From .. To (in that
   --  order) over the common denominator Det: the right-hand side of the
   --  row where the variable is basic, else 0.
   function Extract (T : Tableau; Basis : Basis_List; From : Label_Type; Count : Strategy_Count)
     return Big_Vector
   with
     Global => null,
     Pre    => T'First (2) = 0 and then T'Last (2) >= 0 and then Basis'First = T'First (1)
               and then Basis'Last = T'Last (1),
     Post   => Extract'Result'First = 1 and then Extract'Result'Last = Count
   is
      V : Big_Vector (1 .. Count) := [others => To_Big_Integer (0)];
   begin
      for R in T'Range (1) loop
         if Basis (R) >= From and then Basis (R) - From < Count then
            V (Basis (R) - From + 1) := T (R, 0);
         end if;
      end loop;
      return V;
   end Extract;

   function Find_Equilibrium
     (A, B         : Payoff_Matrix;
      Initial_Drop : Label_Type := 1) return Exact_Equilibrium
   is
      M : constant Strategy_Count := A'Last (1);
      N : constant Strategy_Count := A'Last (2);
      --  P: rows J, s_J + sum B' (I, J) x_I = 1; x_I has label I, s_J
      --  label M + J.  Q: rows I, r_I + sum A' (I, J) y_J = 1; r_I has
      --  label I, y_J label M + J.  A' and B' are A and B shifted so the
      --  smallest entry is 1 (the same best responses).
      P     : Tableau (1 .. N, 0 .. M + N) := [others => [others => To_Big_Integer (0)]];
      Q     : Tableau (1 .. M, 0 .. M + N) := [others => [others => To_Big_Integer (0)]];
      P_Basis : Basis_List (1 .. N) := [for J in 1 .. N => M + J];
      Q_Basis : Basis_List (1 .. M) := [for I in 1 .. M => I];
      P_Det, Q_Det : Big_Integer := To_Big_Integer (1);
      Min_A : Integer := A (1, 1);
      Min_B : Integer := B (1, 1);
      Entering : Label_Type := Initial_Drop;
      Leaving  : Label_Type;
      In_P     : Boolean := Initial_Drop <= M;
      Ok       : Boolean := True;
      Done     : Boolean := False;
      Pivots   : Natural := 0;
      R        : Exact_Equilibrium (M, N);
   begin
      for I in 1 .. M loop
         for J in 1 .. N loop
            Min_A := Integer'Min (Min_A, A (I, J));
            Min_B := Integer'Min (Min_B, B (I, J));
         end loop;
      end loop;
      for I in 1 .. M loop
         for J in 1 .. N loop
            P (J, I) := To_Big_Integer (B (I, J)) - To_Big_Integer (Min_B) + 1;
            Q (I, M + J) := To_Big_Integer (A (I, J)) - To_Big_Integer (Min_A) + 1;
         end loop;
      end loop;
      for J in 1 .. N loop
         P (J, 0) := To_Big_Integer (1);
         P (J, M + J) := To_Big_Integer (1);
      end loop;
      for I in 1 .. M loop
         Q (I, 0) := To_Big_Integer (1);
         Q (I, I) := To_Big_Integer (1);
      end loop;

      --  Complementary pivoting: the variable that leaves one tableau has
      --  a label whose other variable then enters the other tableau, until
      --  the dropped label leaves.  P's slacks are labels M + 1 .. M + N,
      --  Q's 1 .. M.
      for Step in 1 .. Path_Cap (M, N) loop
         if In_P then
            Pivot (P, P_Basis, P_Det, Entering, M + 1, M + N, Leaving, Ok);
         else
            Pivot (Q, Q_Basis, Q_Det, Entering, 1, M, Leaving, Ok);
         end if;
         Pivots := Step;
         pragma Loop_Invariant (P_Det > 0 and then Q_Det > 0);
         pragma Loop_Invariant (Leaving <= M + N);
         pragma Loop_Invariant (for all J in P_Basis'Range => P_Basis (J) <= M + N);
         pragma Loop_Invariant (for all I in Q_Basis'Range => Q_Basis (I) <= M + N);
         pragma Loop_Invariant (Pivots = Step);
         exit when not Ok;
         if Leaving = Initial_Drop then
            Done := True;
            exit;
         end if;
         Entering := Leaving;
         In_P := not In_P;
      end loop;

      R.Pivots := Pivots;
      if Done then
         R.X := Extract (P, P_Basis, 1, M);
         R.Y := Extract (Q, Q_Basis, M + 1, N);
         R.Dx := Sum_To (R.X, M);
         R.Dy := Sum_To (R.Y, N);
         --  The result is certified: Found only when the exact check holds.
         if Is_Nash (A, B, R.X, R.Dx, R.Y, R.Dy) then
            R.Status := Found;
         else
            R.Status := Check_Failed;
         end if;
      else
         --  No path end within Path_Cap (M, N): say which exit was taken; no strategies (Dx = 0
         --  is not a mixed strategy, so Is_Nash is False).
         R.X := [others => To_Big_Integer (0)];
         R.Y := [others => To_Big_Integer (0)];
         R.Dx := To_Big_Integer (0);
         R.Dy := To_Big_Integer (0);
         if Ok then
            R.Status := Step_Cap_Reached;
         else
            R.Status := No_Pivot_Row;
         end if;
      end if;
      return R;
   end Find_Equilibrium;

end Lemke_Howson;
