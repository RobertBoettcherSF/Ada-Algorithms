--  AC_3 package body — Mackworth arc consistency (AC-3) for binary CSPs.

pragma Ada_2022;

package body AC_3
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Domain helpers
   -------------------------------------------------------------------------

   function Empty_Domain return Domain is
   begin
      return [others => False];
   end Empty_Domain;

   function Full_Domain (Dmax : Dom_Size) return Domain is
      D : Domain := [others => False];
   begin
      for V in 1 .. Dmax loop
         D (V) := True;
      end loop;
      return D;
   end Full_Domain;

   function Domain_Size (D : Domain) return Dom_Size is
      N : Dom_Size := 0;
   begin
      for V in Value loop
         if D (V) then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Domain_Size;

   function Is_Empty (D : Domain) return Boolean is
   begin
      return Domain_Size (D) = 0;
   end Is_Empty;

   function Contains (D : Domain; V : Value) return Boolean is
   begin
      return D (V);
   end Contains;

   procedure Remove_Value (D : in out Domain; V : Value) is
   begin
      D (V) := False;
   end Remove_Value;

   procedure Init
     (Problem  : out CSP;
      Num_Vars : Var_Count;
      Dmax     : Dom_Size)
   is
      D : constant Domain := Full_Domain (Dmax);
   begin
      Problem :=
        (Num_Vars        => Num_Vars,
         Num_Constraints => 0,
         Domains         => [others => [others => False]],
         Constraints     =>
           [others => (1, 1, Not_Equal, [others => [others => False]])]);
      for I in 1 .. Num_Vars loop
         Problem.Domains (I) := D;
      end loop;
   end Init;

   procedure Set_Domain
     (Problem : in out CSP;
      Var     : Variable_Id;
      D       : Domain)
   is
   begin
      if Var > Problem.Num_Vars then
         raise Invalid_Argument;
      end if;
      Problem.Domains (Var) := D;
   end Set_Domain;

   -------------------------------------------------------------------------
   -- Constraint builders
   -------------------------------------------------------------------------

   procedure Append_Constraint
     (Problem : in out CSP;
      C       : Constraint)
   is
   begin
      if Problem.Num_Constraints = Max_Constraints then
         raise Capacity_Exceeded;
      end if;
      Problem.Num_Constraints := Problem.Num_Constraints + 1;
      Problem.Constraints (Problem.Num_Constraints) := C;
   end Append_Constraint;

   procedure Add_Not_Equal
     (Problem : in out CSP;
      A, B    : Variable_Id)
   is
   begin
      if A = B or else A > Problem.Num_Vars or else B > Problem.Num_Vars then
         raise Invalid_Argument;
      end if;
      Append_Constraint
        (Problem,
         (Left => A, Right => B, Kind => Not_Equal,
          Allowed => [others => [others => False]]));
   end Add_Not_Equal;

   procedure Add_Less_Than
     (Problem : in out CSP;
      A, B    : Variable_Id)
   is
   begin
      if A = B or else A > Problem.Num_Vars or else B > Problem.Num_Vars then
         raise Invalid_Argument;
      end if;
      Append_Constraint
        (Problem,
         (Left => A, Right => B, Kind => Less_Than,
          Allowed => [others => [others => False]]));
   end Add_Less_Than;

   procedure Add_Allowed_Pairs
     (Problem : in out CSP;
      A, B    : Variable_Id;
      Allowed : Allowed_Matrix)
   is
   begin
      if A = B or else A > Problem.Num_Vars or else B > Problem.Num_Vars then
         raise Invalid_Argument;
      end if;
      Append_Constraint
        (Problem,
         (Left => A, Right => B, Kind => Allowed_Pairs, Allowed => Allowed));
   end Add_Allowed_Pairs;

   procedure Add_All_Different (Problem : in out CSP) is
   begin
      if Problem.Num_Vars < 2 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. Problem.Num_Vars - 1 loop
         for J in I + 1 .. Problem.Num_Vars loop
            Add_Not_Equal (Problem, I, J);
         end loop;
      end loop;
   end Add_All_Different;

   -------------------------------------------------------------------------
   -- Constraint evaluation
   -------------------------------------------------------------------------

   function Satisfies
     (C      : Constraint;
      Vi, Vj : Value) return Boolean
   is
   begin
      case C.Kind is
         when Not_Equal =>
            return Vi /= Vj;
         when Less_Than =>
            return Vi < Vj;
         when Allowed_Pairs =>
            return C.Allowed (Vi, Vj);
      end case;
   end Satisfies;

   --  Evaluate all constraints that involve both Xi and Xj, oriented so
   --  Vi is Xi's value and Vj is Xj's value.
   function Pair_Allowed
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi, Vj  : Value) return Boolean
   is
   begin
      for K in 1 .. Problem.Num_Constraints loop
         declare
            C : Constraint renames Problem.Constraints (K);
         begin
            if C.Left = Xi and then C.Right = Xj then
               if not Satisfies (C, Vi, Vj) then
                  return False;
               end if;
            elsif C.Left = Xj and then C.Right = Xi then
               --  Constraint stored as (Xj, Xi); flip values.
               if not Satisfies (C, Vi => Vj, Vj => Vi) then
                  return False;
               end if;
            end if;
         end;
      end loop;
      return True;
   end Pair_Allowed;

   function Has_Support
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Vi      : Value) return Boolean
   is
   begin
      for Vj in Value loop
         if Problem.Domains (Xj)(Vj)
           and then Pair_Allowed (Problem, Xi, Xj, Vi, Vj)
         then
            return True;
         end if;
      end loop;
      return False;
   end Has_Support;

   function Revise
     (Problem : in out CSP;
      Xi, Xj  : Variable_Id) return Boolean
   is
      Changed : Boolean := False;
   begin
      for Vi in Value loop
         if Problem.Domains (Xi)(Vi) then
            if not Has_Support (Problem, Xi, Xj, Vi) then
               Problem.Domains (Xi)(Vi) := False;
               Changed := True;
            end if;
         end if;
      end loop;
      return Changed;
   end Revise;

   -------------------------------------------------------------------------
   -- Queue helpers
   -------------------------------------------------------------------------

   procedure Fill_Initial_Queue
     (Problem : CSP;
      Queue   : out Arc_Queue;
      Count   : out Arc_Count)
   is
   begin
      Queue := [others => (1, 1)];
      Count := 0;
      for K in 1 .. Problem.Num_Constraints loop
         declare
            C : Constraint renames Problem.Constraints (K);
         begin
            if Count = Max_Arcs then
               raise Capacity_Exceeded;
            end if;
            Count := Count + 1;
            Queue (Count) := (Xi => C.Left, Xj => C.Right);
            if Count = Max_Arcs then
               raise Capacity_Exceeded;
            end if;
            Count := Count + 1;
            Queue (Count) := (Xi => C.Right, Xj => C.Left);
         end;
      end loop;
   end Fill_Initial_Queue;

   function Arc_In_Queue
     (Queue : Arc_Queue;
      Count : Arc_Count;
      A     : Arc) return Boolean
   is
   begin
      for I in 1 .. Count loop
         if Queue (I).Xi = A.Xi and then Queue (I).Xj = A.Xj then
            return True;
         end if;
      end loop;
      return False;
   end Arc_In_Queue;

   procedure Enqueue_Neighbors
     (Problem : CSP;
      Xi, Xj  : Variable_Id;
      Queue   : in out Arc_Queue;
      Count   : in out Arc_Count)
   is
   --  After revising (Xi, Xj), enqueue (Xk, Xi) for every neighbour Xk /= Xj.
   begin
      for K in 1 .. Problem.Num_Constraints loop
         declare
            C  : Constraint renames Problem.Constraints (K);
            Nk : Variable_Id;
            Ok : Boolean := False;
         begin
            if C.Left = Xi then
               Nk := C.Right;
               Ok := True;
            elsif C.Right = Xi then
               Nk := C.Left;
               Ok := True;
            end if;
            if Ok and then Nk /= Xj then
               declare
                  A : constant Arc := (Xi => Nk, Xj => Xi);
               begin
                  if not Arc_In_Queue (Queue, Count, A) then
                     if Count = Max_Arcs then
                        raise Capacity_Exceeded;
                     end if;
                     Count := Count + 1;
                     Queue (Count) := A;
                  end if;
               end;
            end if;
         end;
      end loop;
   end Enqueue_Neighbors;

   -------------------------------------------------------------------------
   -- AC-3
   -------------------------------------------------------------------------

   procedure AC3
     (Problem : in out CSP;
      Result  : out AC3_Result)
   is
      Queue : Arc_Queue;
      Count : Arc_Count := 0;
      Head  : Natural := 1;
   begin
      Result := (Status => Success, Revisions => 0, Arcs_Processed => 0);
      Fill_Initial_Queue (Problem, Queue, Count);

      while Head <= Count loop
         declare
            A       : constant Arc := Queue (Head);
            Changed : Boolean;
         begin
            Head := Head + 1;
            Result.Arcs_Processed := Result.Arcs_Processed + 1;
            Changed := Revise (Problem, A.Xi, A.Xj);
            if Changed then
               Result.Revisions := Result.Revisions + 1;
               if Is_Empty (Problem.Domains (A.Xi)) then
                  Result.Status := Domain_Wipeout;
                  return;
               end if;
               Enqueue_Neighbors (Problem, A.Xi, A.Xj, Queue, Count);
            end if;
         end;
      end loop;
   end AC3;

   procedure Make_Arc_Consistent
     (Problem : in out CSP;
      Result  : out AC3_Result)
   is
   begin
      AC3 (Problem, Result);
   end Make_Arc_Consistent;

   -------------------------------------------------------------------------
   -- Demo builders
   -------------------------------------------------------------------------

   --  Australia map variable ids:
   --  1=WA  2=NT  3=SA  4=Q  5=NSW  6=V  7=T
   procedure Build_Australia_Map (Problem : out CSP) is
   begin
      Init (Problem, Num_Vars => 7, Dmax => 3);
      --  Borders (undirected; Add_Not_Equal stores one undirected edge)
      Add_Not_Equal (Problem, 1, 2); -- WA-NT
      Add_Not_Equal (Problem, 1, 3); -- WA-SA
      Add_Not_Equal (Problem, 2, 3); -- NT-SA
      Add_Not_Equal (Problem, 2, 4); -- NT-Q
      Add_Not_Equal (Problem, 3, 4); -- SA-Q
      Add_Not_Equal (Problem, 3, 5); -- SA-NSW
      Add_Not_Equal (Problem, 3, 6); -- SA-V
      Add_Not_Equal (Problem, 4, 5); -- Q-NSW
      Add_Not_Equal (Problem, 5, 6); -- NSW-V
      --  T (7) is isolated — no edges
   end Build_Australia_Map;

   procedure Build_Unsat_Triangle (Problem : out CSP) is
   begin
      Init (Problem, Num_Vars => 3, Dmax => 2);
      Add_Not_Equal (Problem, 1, 2);
      Add_Not_Equal (Problem, 2, 3);
      Add_Not_Equal (Problem, 1, 3);
   end Build_Unsat_Triangle;

   procedure Build_N_Queens_Binary
     (Problem : out CSP;
      N       : Positive)
   is
   begin
      Init (Problem, Num_Vars => N, Dmax => N);
      for I in 1 .. N - 1 loop
         for J in I + 1 .. N loop
            declare
               Diff    : constant Positive := J - I;
               Allowed : Allowed_Matrix := [others => [others => False]];
            begin
               for Ci in 1 .. N loop
                  for Cj in 1 .. N loop
                     --  Different columns and not on same diagonal.
                     if Ci /= Cj
                       and then abs (Ci - Cj) /= Diff
                     then
                        Allowed (Ci, Cj) := True;
                     end if;
                  end loop;
               end loop;
               Add_Allowed_Pairs (Problem, I, J, Allowed);
            end;
         end loop;
      end loop;
   end Build_N_Queens_Binary;

   procedure Build_Alldiff_Demo
     (Problem : out CSP;
      N       : Positive;
      Dmax    : Dom_Size)
   is
   begin
      Init (Problem, Num_Vars => N, Dmax => Dmax);
      Add_All_Different (Problem);
   end Build_Alldiff_Demo;

end AC_3;
