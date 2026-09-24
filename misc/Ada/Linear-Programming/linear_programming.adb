--  Linear_Programming body — survey: form helpers, Bland two-phase
--  Maximize/Minimize, weak duality / complementary slackness, 2-D
--  graphical vertices, method taxonomy.

pragma Ada_2022;

package body Linear_Programming
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Near / Vec_Near / Dot / Objective_Value
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for K in 0 .. A'Length - 1 loop
         if abs (A (A'First + K) - B (B'First + K)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Dot (A, B : Vector) return Real is
      S : Real := 0.0;
   begin
      for K in 0 .. A'Length - 1 loop
         S := S + A (A'First + K) * B (B'First + K);
      end loop;
      return S;
   end Dot;

   function Objective_Value (C, X : Vector) return Real is
   begin
      return Dot (C, X);
   end Objective_Value;

   -------------------------------------------------------------------------
   -- Taxonomy
   -------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Simplex =>
            return (Kind => Simplex,
                    Polynomial_Worst_Case => False,
                    Uses_Basis_Exchange   => True,
                    Fully_Implemented     => True);
         when Interior_Point =>
            return (Kind => Interior_Point,
                    Polynomial_Worst_Case => True,
                    Uses_Basis_Exchange   => False,
                    Fully_Implemented     => False);
         when Ellipsoid =>
            return (Kind => Ellipsoid,
                    Polynomial_Worst_Case => True,
                    Uses_Basis_Exchange   => False,
                    Fully_Implemented     => False);
         when Dual_Simplex =>
            return (Kind => Dual_Simplex,
                    Polynomial_Worst_Case => False,
                    Uses_Basis_Exchange   => True,
                    Fully_Implemented     => False);
      end case;
   end Classify_Method;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Simplex        => return "Simplex";
         when Interior_Point => return "Interior_Point";
         when Ellipsoid      => return "Ellipsoid";
         when Dual_Simplex   => return "Dual_Simplex";
      end case;
   end Method_Name;

   function Form_Name (Kind : Form_Kind) return String is
   begin
      case Kind is
         when Canonical => return "Canonical";
         when Standard_Equality  => return "Standard_Equality";
         when Slack     => return "Slack";
      end case;
   end Form_Name;

   function Method_Count return Natural is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
           - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   function Form_Count return Natural is
   begin
      return Form_Kind'Pos (Form_Kind'Last)
           - Form_Kind'Pos (Form_Kind'First) + 1;
   end Form_Count;

   -------------------------------------------------------------------------
   -- Matrix helpers / feasibility
   -------------------------------------------------------------------------

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      R : Vector (A'Range (1));
      S : Real;
   begin
      for I in A'Range (1) loop
         S := 0.0;
         for J in A'Range (2) loop
            S := S + A (I, J) * X (X'First + (J - A'First (2)));
         end loop;
         R (I) := S;
      end loop;
      return R;
   end Mat_Vec;

   function Mat_T_Vec (A : Matrix; Y : Vector) return Vector is
      R : Vector (A'Range (2));
      S : Real;
   begin
      for J in A'Range (2) loop
         S := 0.0;
         for I in A'Range (1) loop
            S := S + A (I, J) * Y (Y'First + (I - A'First (1)));
         end loop;
         R (J) := S;
      end loop;
      return R;
   end Mat_T_Vec;

   function Primal_Slack
     (A : Matrix; B, X : Vector) return Vector
   is
      Ax : constant Vector := Mat_Vec (A, X);
      W  : Vector (B'Range);
   begin
      for K in 0 .. B'Length - 1 loop
         W (B'First + K) := B (B'First + K) - Ax (Ax'First + K);
      end loop;
      return W;
   end Primal_Slack;

   function Dual_Slack
     (A : Matrix; C, Y : Vector) return Vector
   is
      ATy : constant Vector := Mat_T_Vec (A, Y);
      Z   : Vector (C'Range);
   begin
      for K in 0 .. C'Length - 1 loop
         Z (C'First + K) := ATy (ATy'First + K) - C (C'First + K);
      end loop;
      return Z;
   end Dual_Slack;

   function Is_Nonnegative
     (V : Vector; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      for E of V loop
         if E < -Tol then
            return False;
         end if;
      end loop;
      return True;
   end Is_Nonnegative;

   function Feasible_Inequality
     (A   : Matrix;
      B   : Vector;
      X   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
      W : constant Vector := Primal_Slack (A, B, X);
   begin
      return Is_Nonnegative (W, Tol) and then Is_Nonnegative (X, Tol);
   end Feasible_Inequality;

   function Dual_Feasible
     (A   : Matrix;
      C   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
      Z : constant Vector := Dual_Slack (A, C, Y);
   begin
      return Is_Nonnegative (Z, Tol) and then Is_Nonnegative (Y, Tol);
   end Dual_Feasible;

   procedure Append_Slacks
     (A     : Matrix;
      Out_A : out Matrix)
   is
      M : constant Constraint_Count := A'Length (1);
      N : constant Var_Count := A'Length (2);
   begin
      for I in Out_A'Range (1) loop
         for J in Out_A'Range (2) loop
            Out_A (I, J) := 0.0;
         end loop;
      end loop;
      for I in 0 .. M - 1 loop
         for J in 0 .. N - 1 loop
            Out_A (Out_A'First (1) + I, Out_A'First (2) + J) :=
              A (A'First (1) + I, A'First (2) + J);
         end loop;
         --  Identity slack block.
         Out_A (Out_A'First (1) + I, Out_A'First (2) + N + I) := 1.0;
      end loop;
   end Append_Slacks;

   function Slack_Column_Count (M_Rows : Constraint_Count) return Var_Count is
   begin
      return Var_Count (M_Rows);
   end Slack_Column_Count;

   -------------------------------------------------------------------------
   -- Duality helpers
   -------------------------------------------------------------------------

   function Duality_Gap
     (C, X, B, Y : Vector) return Real
   is
   begin
      return Dot (B, Y) - Dot (C, X);
   end Duality_Gap;

   function Weak_Duality_Holds
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      if not Feasible_Inequality (A, B, X, Tol) then
         return False;
      end if;
      if not Dual_Feasible (A, C, Y, Tol) then
         return False;
      end if;
      return Dot (C, X) <= Dot (B, Y) + Tol;
   end Weak_Duality_Holds;

   function Complementary_Slackness_Holds
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      X   : Vector;
      Y   : Vector;
      Tol : Real := Epsilon_Tol) return Boolean
   is
      W : constant Vector := Primal_Slack (A, B, X);
      Z : constant Vector := Dual_Slack (A, C, Y);
   begin
      for K in 0 .. X'Length - 1 loop
         if abs (X (X'First + K) * Z (Z'First + K)) > Tol then
            return False;
         end if;
      end loop;
      for K in 0 .. Y'Length - 1 loop
         if abs (W (W'First + K) * Y (Y'First + K)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Complementary_Slackness_Holds;

   -------------------------------------------------------------------------
   -- Active objective / entering / leaving / pivot
   -------------------------------------------------------------------------

   function Active_Obj_Row (Tab : Tableau) return Natural is
   begin
      if Tab.Obj_Phase1 > 0 then
         return Tab.Obj_Phase1;
      end if;
      return 0;
   end Active_Obj_Row;

   function Select_Entering
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Natural
   is
      R : constant Natural := Active_Obj_Row (Tab);
   begin
      for J in 1 .. Tab.N loop
         if Tab.T (R, J) < -Tol then
            return J;
         end if;
      end loop;
      return 0;
   end Select_Entering;

   function Is_Optimal_LP
     (Tab : Tableau; Tol : Real := Epsilon_Tol) return Boolean
   is
   begin
      return Select_Entering (Tab, Tol) = 0;
   end Is_Optimal_LP;

   function Select_Leaving
     (Tab       : Tableau;
      Enter_Col : Positive;
      Tol       : Real := Epsilon_Tol) return Natural
   is
      Best_Ratio : Real := Real'Last;
      Best_Row   : Natural := 0;
      Best_Basic : Natural := Natural'Last;
      Ratio      : Real;
      Aij        : Real;
   begin
      for I in 1 .. Tab.M loop
         Aij := Tab.T (I, Enter_Col);
         if Aij > Tol then
            Ratio := Tab.T (I, 0) / Aij;
            if Ratio + Tol < Best_Ratio then
               Best_Ratio := Ratio;
               Best_Row   := I;
               Best_Basic := Tab.Basic (I);
            elsif abs (Ratio - Best_Ratio) <= Tol
              and then Tab.Basic (I) < Best_Basic
            then
               Best_Row   := I;
               Best_Basic := Tab.Basic (I);
            end if;
         end if;
      end loop;
      return Best_Row;
   end Select_Leaving;

   procedure Pivot
     (Tab                  : in out Tableau;
      Leave_Row, Enter_Col : Positive)
   is
      Pivot_Val : constant Real := Tab.T (Leave_Row, Enter_Col);
      Factor    : Real;
      Last_Row  : Natural;
   begin
      if abs (Pivot_Val) < Real'Model_Small then
         raise Invalid_Argument with "Pivot: near-zero pivot element";
      end if;

      for J in 0 .. Tab.N loop
         Tab.T (Leave_Row, J) := Tab.T (Leave_Row, J) / Pivot_Val;
      end loop;

      Last_Row := Tab.M;
      if Tab.Obj_Phase1 > Last_Row then
         Last_Row := Tab.Obj_Phase1;
      end if;

      for I in 0 .. Last_Row loop
         if I /= Leave_Row then
            Factor := Tab.T (I, Enter_Col);
            if Factor /= 0.0 then
               for J in 0 .. Tab.N loop
                  Tab.T (I, J) :=
                    Tab.T (I, J) - Factor * Tab.T (Leave_Row, J);
               end loop;
            end if;
         end if;
      end loop;

      Tab.Basic (Leave_Row) := Enter_Col;
   end Pivot;

   -------------------------------------------------------------------------
   -- Extract_Primal / Build_Tableau
   -------------------------------------------------------------------------

   function Extract_Primal
     (Tab : Tableau; N_Decision : Var_Count) return Vector
   is
      X : Vector (1 .. Max_Vars) := [others => 0.0];
   begin
      for I in 1 .. Tab.M loop
         declare
            Bv : constant Natural := Tab.Basic (I);
         begin
            if Bv >= 1 and then Bv <= Natural (N_Decision) then
               X (Bv) := Tab.T (I, 0);
            end if;
         end;
      end loop;
      if N_Decision = 0 then
         declare
            Empty : Vector (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      return X (1 .. N_Decision);
   end Extract_Primal;

   function Build_Tableau
     (A : Matrix; B, C : Vector) return Tableau
   is
      M_Cons : constant Constraint_Count := A'Length (1);
      N_Dec  : constant Var_Count := A'Length (2);
      Tab    : Tableau;
      Art_Count : Var_Count := 0;
      Row_Sign  : array (1 .. Max_Constraints) of Real := [others => 1.0];
      Art_Col_Base : Var_Count;
      Art_Used     : Var_Count;
      Slack_Col    : Var_Index;
      Art_Col      : Var_Index;
      Bi           : Real;
   begin
      if M_Cons = 0 or else N_Dec = 0 then
         raise Invalid_Argument with "Build_Tableau: empty problem";
      end if;
      if N_Dec + M_Cons > Max_Vars then
         raise Invalid_Argument with "Build_Tableau: too many columns";
      end if;

      for I in 1 .. M_Cons loop
         if B (B'First + I - 1) < 0.0 then
            Row_Sign (I) := -1.0;
            Art_Count := Art_Count + 1;
         end if;
      end loop;

      if N_Dec + M_Cons + Art_Count > Max_Vars then
         raise Invalid_Argument with "Build_Tableau: artificial overflow";
      end if;

      Tab.M            := M_Cons;
      Tab.N_Decision   := N_Dec;
      Tab.N_Slack      := M_Cons;
      Tab.N_Artificial := Art_Count;
      Tab.N            := N_Dec + M_Cons + Art_Count;
      Tab.Obj_Phase1   := 0;

      for I in 0 .. Max_Constraints loop
         for J in 0 .. Max_Vars loop
            Tab.T (I, J) := 0.0;
         end loop;
      end loop;
      for I in 1 .. Max_Constraints loop
         Tab.Basic (I) := 0;
      end loop;

      Tab.T (0, 0) := 0.0;
      for J in 1 .. N_Dec loop
         Tab.T (0, J) := -C (C'First + J - 1);
      end loop;

      Art_Col_Base := N_Dec + M_Cons;
      Art_Used := 0;

      for I in 1 .. M_Cons loop
         Bi := Row_Sign (I) * B (B'First + I - 1);
         Tab.T (I, 0) := Bi;
         for J in 1 .. N_Dec loop
            Tab.T (I, J) :=
              Row_Sign (I)
              * A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;

         Slack_Col := Var_Index (N_Dec + I);
         if Row_Sign (I) > 0.0 then
            Tab.T (I, Slack_Col) := 1.0;
            Tab.Basic (I) := Slack_Col;
         else
            Tab.T (I, Slack_Col) := -1.0;
            Art_Used := Art_Used + 1;
            Art_Col := Var_Index (Art_Col_Base + Art_Used);
            Tab.T (I, Art_Col) := 1.0;
            Tab.Basic (I) := Art_Col;
         end if;
      end loop;

      if Art_Count > 0 then
         Tab.Obj_Phase1 := Natural (M_Cons) + 1;
         if Tab.Obj_Phase1 > Max_Constraints then
            raise Invalid_Argument
              with "Build_Tableau: no room for Phase-I row";
         end if;
         for J in 0 .. Tab.N loop
            Tab.T (Tab.Obj_Phase1, J) := 0.0;
         end loop;
         for K in 1 .. Art_Count loop
            Art_Col := Var_Index (Art_Col_Base + K);
            Tab.T (Tab.Obj_Phase1, Art_Col) := -1.0;
         end loop;
         for I in 1 .. M_Cons loop
            if Tab.Basic (I) > Natural (N_Dec + M_Cons) then
               for J in 0 .. Tab.N loop
                  Tab.T (Tab.Obj_Phase1, J) :=
                    Tab.T (Tab.Obj_Phase1, J) + Tab.T (I, J);
               end loop;
            end if;
         end loop;
         for J in 0 .. Tab.N loop
            Tab.T (Tab.Obj_Phase1, J) := -Tab.T (Tab.Obj_Phase1, J);
         end loop;
      end if;

      return Tab;
   end Build_Tableau;

   -------------------------------------------------------------------------
   -- Drop artificials / Run_Phase / Solve_Tableau
   -------------------------------------------------------------------------

   procedure Drop_Artificials (Tab : in out Tableau) is
      First_Art : constant Var_Count := Tab.N_Decision + Tab.N_Slack + 1;
      New_N     : constant Var_Count := Tab.N_Decision + Tab.N_Slack;
      Enter     : Natural;
   begin
      if Tab.N_Artificial = 0 then
         Tab.Obj_Phase1 := 0;
         return;
      end if;

      for I in 1 .. Tab.M loop
         if Tab.Basic (I) >= Natural (First_Art) then
            Enter := 0;
            for J in 1 .. New_N loop
               if abs (Tab.T (I, J)) > Epsilon_Tol then
                  Enter := J;
                  exit;
               end if;
            end loop;
            if Enter > 0 then
               Pivot (Tab, I, Enter);
            end if;
         end if;
      end loop;

      Tab.N := New_N;
      Tab.N_Artificial := 0;
      if Tab.Obj_Phase1 > 0 then
         for J in 0 .. Max_Vars loop
            Tab.T (Tab.Obj_Phase1, J) := 0.0;
         end loop;
      end if;
      Tab.Obj_Phase1 := 0;
   end Drop_Artificials;

   function Run_Phase
     (Tab          : in out Tableau;
      Cfg          : Config;
      Pivot_Budget : in out Natural) return Status
   is
      Enter, Leave : Natural;
   begin
      loop
         Enter := Select_Entering (Tab, Cfg.Tol);
         if Enter = 0 then
            return Optimal;
         end if;
         Leave := Select_Leaving (Tab, Enter, Cfg.Tol);
         if Leave = 0 then
            return Unbounded;
         end if;
         if Pivot_Budget = 0 then
            return Iteration_Limit;
         end if;
         Pivot (Tab, Leave, Enter);
         Pivot_Budget := Pivot_Budget - 1;
      end loop;
   end Run_Phase;

   function Solve_Tableau
     (Tab : in out Tableau;
      Cfg : Config := Default_Config) return Result
   is
      R            : Result;
      Phase_Stat   : Status;
      Budget       : Natural := Cfg.Max_Pivots;
      Pivots_Start : constant Natural := Budget;
      Phase1_Obj   : Real;
   begin
      if Tab.M = 0 or else Tab.N = 0 then
         raise Invalid_Argument with "Solve_Tableau: empty tableau";
      end if;

      R.N_Vars := Tab.N_Decision;

      if Tab.N_Artificial > 0 and then Tab.Obj_Phase1 > 0 then
         Phase_Stat := Run_Phase (Tab, Cfg, Budget);
         R.N_Pivots := Pivots_Start - Budget;

         if Phase_Stat = Unbounded or else Phase_Stat = Iteration_Limit
           or else Phase_Stat = Infeasible
         then
            R.Stat := Infeasible;
            R.Success := False;
            return R;
         end if;

         Phase1_Obj := Tab.T (Tab.Obj_Phase1, 0);
         if Phase1_Obj < -Cfg.Tol then
            R.Stat := Infeasible;
            R.Objective := Phase1_Obj;
            R.Success := False;
            return R;
         end if;

         Drop_Artificials (Tab);
      end if;

      Phase_Stat := Run_Phase (Tab, Cfg, Budget);
      R.N_Pivots := Pivots_Start - Budget;

      case Phase_Stat is
         when Optimal =>
            R.Stat := Optimal;
            R.Objective := Tab.T (0, 0);
            declare
               X_Dec : constant Vector :=
                 Extract_Primal (Tab, Tab.N_Decision);
            begin
               for J in 1 .. Tab.N_Decision loop
                  R.X (J) := X_Dec (J);
               end loop;
            end;
            R.Success := True;
         when Unbounded =>
            R.Stat := Unbounded;
            R.Objective := Tab.T (0, 0);
            declare
               X_Dec : constant Vector :=
                 Extract_Primal (Tab, Tab.N_Decision);
            begin
               for J in 1 .. Tab.N_Decision loop
                  R.X (J) := X_Dec (J);
               end loop;
            end;
            R.Success := False;
         when Infeasible | Iteration_Limit =>
            R.Stat := Phase_Stat;
            R.Success := False;
      end case;

      return R;
   end Solve_Tableau;

   function Maximize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
   is
      Tab : Tableau := Build_Tableau (A, B, C);
   begin
      return Solve_Tableau (Tab, Cfg);
   end Maximize;

   function Minimize
     (A   : Matrix;
      B   : Vector;
      C   : Vector;
      Cfg : Config := Default_Config) return Result
   is
      Neg_C : Vector (C'Range);
      R     : Result;
   begin
      for K in C'Range loop
         Neg_C (K) := -C (K);
      end loop;
      R := Maximize (A, B, Neg_C, Cfg);
      if R.Stat = Optimal or else R.Stat = Unbounded then
         R.Objective := -R.Objective;
      end if;
      return R;
   end Minimize;

   -------------------------------------------------------------------------
   -- Graphical 2-D vertices
   -------------------------------------------------------------------------

   function Point_Feasible
     (P : Point2; A : Matrix; B : Vector; Tol : Real) return Boolean
   is
      Ax : Real;
   begin
      if P.X < -Tol or else P.Y < -Tol then
         return False;
      end if;
      for I in A'Range (1) loop
         Ax := A (I, A'First (2)) * P.X + A (I, A'First (2) + 1) * P.Y;
         if Ax > B (B'First + (I - A'First (1))) + Tol then
            return False;
         end if;
      end loop;
      return True;
   end Point_Feasible;

   function Points_Near (P, Q : Point2; Tol : Real) return Boolean is
   begin
      return abs (P.X - Q.X) <= Tol and then abs (P.Y - Q.Y) <= Tol;
   end Points_Near;

   procedure Try_Add
     (List : in out Vertex_List;
      P    : Point2;
      A    : Matrix;
      B    : Vector;
      Tol  : Real)
   is
   begin
      if not Point_Feasible (P, A, B, Tol) then
         return;
      end if;
      for K in 1 .. List.Count loop
         if Points_Near (List.Points (K), P, Tol * 10.0) then
            return;
         end if;
      end loop;
      if List.Count < Max_Vertices then
         List.Count := List.Count + 1;
         List.Points (List.Count) := P;
      end if;
   end Try_Add;

   --  Solve a11 x + a12 y = b1, a21 x + a22 y = b2.
   function Intersect
     (A11, A12, B1, A21, A22, B2 : Real; Tol : Real; Ok : out Boolean)
      return Point2
   is
      Det : constant Real := A11 * A22 - A12 * A21;
      P   : Point2;
   begin
      if abs (Det) <= Tol then
         Ok := False;
         return P;
      end if;
      P.X := (B1 * A22 - A12 * B2) / Det;
      P.Y := (A11 * B2 - B1 * A21) / Det;
      Ok := True;
      return P;
   end Intersect;

   function Feasible_Vertices_2D
     (A   : Matrix;
      B   : Vector;
      Tol : Real := Epsilon_Tol) return Vertex_List
   is
      List : Vertex_List;
      M    : constant Constraint_Count := A'Length (1);
      Ok   : Boolean;
      P    : Point2;
      --  Line i: A(i,1) x + A(i,2) y = B(i); also axes x=0, y=0.
      --  Encode axes as extra "constraints" with indices M+1, M+2.
      function Coeff
        (Idx : Natural; Col : Positive) return Real
      is
      begin
         if Idx <= Natural (M) then
            return A (A'First (1) + Idx - 1, A'First (2) + Col - 1);
         elsif Idx = Natural (M) + 1 then
            --  x = 0  ⇒  1·x + 0·y = 0
            if Col = 1 then
               return 1.0;
            else
               return 0.0;
            end if;
         else
            --  y = 0  ⇒  0·x + 1·y = 0
            if Col = 2 then
               return 1.0;
            else
               return 0.0;
            end if;
         end if;
      end Coeff;

      function Rhs (Idx : Natural) return Real is
      begin
         if Idx <= Natural (M) then
            return B (B'First + Idx - 1);
         else
            return 0.0;
         end if;
      end Rhs;

      N_Lines : constant Natural := Natural (M) + 2;
   begin
      --  Origin.
      Try_Add (List, (0.0, 0.0), A, B, Tol);

      for I in 1 .. N_Lines loop
         for J in I + 1 .. N_Lines loop
            P := Intersect
              (Coeff (I, 1), Coeff (I, 2), Rhs (I),
               Coeff (J, 1), Coeff (J, 2), Rhs (J),
               Tol, Ok);
            if Ok then
               Try_Add (List, P, A, B, Tol);
            end if;
         end loop;
      end loop;

      return List;
   end Feasible_Vertices_2D;

   function Evaluate_At (P : Point2; C : Vector) return Real is
   begin
      return C (C'First) * P.X + C (C'First + 1) * P.Y;
   end Evaluate_At;

   function Best_Vertex
     (Verts : Vertex_List;
      C     : Vector;
      Sense : Character := 'M') return Point2
   is
      Best : Point2;
      Best_Val : Real;
      Val : Real;
   begin
      if Verts.Count = 0 then
         raise Invalid_Argument with "Best_Vertex: empty vertex list";
      end if;
      Best := Verts.Points (1);
      Best_Val := Evaluate_At (Best, C);
      for K in 2 .. Verts.Count loop
         Val := Evaluate_At (Verts.Points (K), C);
         if Sense = 'M' then
            if Val > Best_Val then
               Best_Val := Val;
               Best := Verts.Points (K);
            end if;
         else
            if Val < Best_Val then
               Best_Val := Val;
               Best := Verts.Points (K);
            end if;
         end if;
      end loop;
      return Best;
   end Best_Vertex;

end Linear_Programming;
