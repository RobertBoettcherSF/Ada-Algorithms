--  Own checks (see tests/SOURCES.txt). Assume the evaluator is wrong or does
--  nothing. Random 3-CNF formulas over propositional atoms are encoded in
--  first-order logic: atom i is the unary predicate T (x_i), where T (v)
--  holds iff v = 2 in the domain 1 .. 3. Then
--  * for every bit mask (assignment) the CNF value computed here directly
--    from the bits must equal Evaluate_Formula under the matching
--    environment (x_i = 2 for a true bit, 1 or 3 for a false one);
--  * Exists x_1 ... Exists x_n CNF must be True exactly when brute force
--    over all 2**N bit masks finds a model (the quantifier code is checked
--    against plain enumeration); Forall x_1 ... CNF exactly when every
--    mask is a model; SAT and UNSAT agreement counted separately;
--  * pigeonhole PHP(3,2) is UNSAT;
--  * substitution lemma: substituting the constant c (value 2) for x_1 in
--    the CNF gives the value the CNF has with x_1 = 2.
pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with First_Order_Logic; use First_Order_Logic;

procedure Own_Checks is
   Seed : Long_Long_Integer := 20261008;
   Failures : Natural := 0;

   function Rand (Lo, Hi : Integer) return Integer is   --  Park-Miller
   begin
      Seed := (Seed * 16807) mod 2147483647;
      return Lo + Integer (Seed mod Long_Long_Integer (Hi - Lo + 1));
   end Rand;

   procedure Fail (What : String) is
   begin
      Put_Line ("FAIL own check: " & What);
      Failures := Failures + 1;
   end Fail;

   type Interp is new Interpretation with null record;
   overriding function Eval_Constant (I : Interp; Name : Character) return Domain_Element;
   overriding function Eval_Function (I : Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Domain_Element;
   overriding function Eval_Predicate (I : Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Boolean;
   overriding function Eval_Constant (I : Interp; Name : Character) return Domain_Element is
      pragma Unreferenced (I, Name);
   begin
      return 2;
   end Eval_Constant;
   overriding function Eval_Function (I : Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Domain_Element is
      pragma Unreferenced (I, Name, Arg2);
   begin
      return Arg1;
   end Eval_Function;
   overriding function Eval_Predicate (I : Interp; Name : Character; Arg1, Arg2 : Domain_Element) return Boolean is
      pragma Unreferenced (I, Name, Arg2);
   begin
      return Arg1 = 2;
   end Eval_Predicate;
   I : Interp;

   Max_N : constant := 9;
   type Lits is array (1 .. 3) of Integer;      --  0 = unused
   type Clauses is array (1 .. 64) of Lits;
   N, M : Natural := 0;
   C : Clauses;

   function Var (K : Positive) return Variable_Name is (Character'Val (Character'Pos ('a') + K - 1));

   function To_FOL return Formula_Access is
      F : Formula_Access := null;
   begin
      for J in 1 .. M loop
         declare
            D : Formula_Access := null;
         begin
            for L of C (J) loop
               if L /= 0 then
                  declare
                     A : constant Formula_Access := Make_Predicate ('T', Make_Variable (Var (abs L)));
                     X : constant Formula_Access := (if L > 0 then A else Make_Not (A));
                  begin
                     D := (if D = null then X else Make_Or (D, X));
                  end;
               end if;
            end loop;
            F := (if F = null then D else Make_And (F, D));
         end;
      end loop;
      return F;
   end To_FOL;

   function Bit (Mask, K : Natural) return Boolean is ((Mask / 2 ** (K - 1)) mod 2 = 1);

   function CNF_True (Mask : Natural) return Boolean is
     (for all J in 1 .. M => (for some L of C (J) => L /= 0 and then Bit (Mask, abs L) = (L > 0)));

   function Env_Of (Mask : Natural) return Assignment is
      E : Assignment := [others => 1];
   begin
      for K in 1 .. N loop
         E (Var (K)) := (if Bit (Mask, K) then 2 else Domain_Element (Rand (0, 1) * 2 + 1));
      end loop;
      return E;
   end Env_Of;

   Sat_Agree, Sat_Total, Unsat_Agree, Unsat_Total : Natural := 0;

   procedure Check_Formula (Label : String) is
      F  : constant Formula_Access := To_FOL;
      Ex, All_F : Formula_Access := F;
      Any_Model, All_Models : Boolean := False;
      Base : constant Assignment := [others => 1];
   begin
      All_Models := True;
      for Mask in 0 .. 2 ** N - 1 loop
         declare
            Want : constant Boolean := CNF_True (Mask);
         begin
            Any_Model := Any_Model or Want;
            All_Models := All_Models and Want;
            if Evaluate_Formula (F, I, Env_Of (Mask)) /= Want then
               Fail (Label & ": Evaluate_Formula disagrees with the CNF at mask" & Mask'Image);
               exit;
            end if;
         end;
      end loop;
      for K in reverse 1 .. N loop
         Ex := Make_Exists (Var (K), Ex);
         All_F := Make_Forall (Var (K), All_F);
      end loop;
      if Evaluate_Formula (Ex, I, Base) /= Any_Model then
         Fail (Label & ": Exists-closure gives " & Boolean'Image (not Any_Model) & ", brute force SAT=" & Any_Model'Image);
      elsif Any_Model then
         Sat_Agree := Sat_Agree + 1;
      else
         Unsat_Agree := Unsat_Agree + 1;
      end if;
      if Any_Model then Sat_Total := Sat_Total + 1; else Unsat_Total := Unsat_Total + 1; end if;
      if Evaluate_Formula (All_F, I, Base) /= All_Models then
         Fail (Label & ": Forall-closure disagrees with brute force");
      end if;
      --  substitution lemma for x_1 := c (value 2)
      declare
         S : constant Formula_Access := Substitute_Formula (F, Var (1), Make_Constant ('c'));
      begin
         for Mask in 0 .. 2 ** N - 1 loop
            if Evaluate_Formula (S, I, Env_Of (Mask)) /= CNF_True (Mask mod 2 ** N / 2 * 2 + 1) then
               Fail (Label & ": substitution lemma fails at mask" & Mask'Image);
               exit;
            end if;
         end loop;
         if N > 1 and then Is_Free_Variable (S, Var (1)) then
            Fail (Label & ": x_1 still free after substitution");
         end if;
      end;
      if not Is_Prenex_Normal_Form (Ex) or else not Has_Quantifier (Ex) or else Is_Free_Variable (Ex, Var (1))
        or else Has_Quantifier (F)
      then
         Fail (Label & ": structural predicates on the closures");
      end if;
   end Check_Formula;

begin
   for Round in 1 .. 80 loop
      N := 5 + Round mod (Max_N - 4);
      M := (N * (if Round mod 2 = 1 then 426 else 520) + 50) / 100;
      for J in 1 .. M loop
         C (J) := [0, 0, 0];
         for K in 1 .. 3 loop
            declare
               V : Integer;
            begin
               loop
                  V := Rand (1, N);
                  exit when (for all P in 1 .. K - 1 => abs C (J) (P) /= V);
               end loop;
               C (J) (K) := (if Rand (0, 1) = 1 then V else -V);
            end;
         end loop;
      end loop;
      Check_Formula ("3-CNF#" & Round'Image);
   end loop;
   --  PHP(3,2): x_(2(i-1)+j) = pigeon i in hole j
   N := 6; M := 0;
   for P in 1 .. 3 loop
      M := M + 1; C (M) := [2 * (P - 1) + 1, 2 * (P - 1) + 2, 0];
   end loop;
   for H in 1 .. 2 loop
      for P1 in 1 .. 3 loop
         for P2 in P1 + 1 .. 3 loop
            M := M + 1; C (M) := [-(2 * (P1 - 1) + H), -(2 * (P2 - 1) + H), 0];
         end loop;
      end loop;
   end loop;
   Check_Formula ("PHP(3,2)");
   if Unsat_Agree = 0 then
      Fail ("PHP(3,2) not reported UNSAT");
   end if;
   Put_Line ("own checks: Exists-closure SAT" & Sat_Agree'Image & " /" & Sat_Total'Image
             & ", UNSAT" & Unsat_Agree'Image & " /" & Unsat_Total'Image & " (incl. PHP(3,2))");
   if Failures > 0 then
      raise Program_Error with "own checks:" & Failures'Image & " failures";
   end if;
end Own_Checks;
