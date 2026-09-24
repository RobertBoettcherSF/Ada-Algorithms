package body Description_Logic is

   -----------------------------------------------------------------------------
   -- Expression Builders
   -----------------------------------------------------------------------------

   function Add_Top (Expr : in out Concept_Expression) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Top);
      return Expr.Last;
   end Add_Top;

   function Add_Bottom (Expr : in out Concept_Expression) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Bottom);
      return Expr.Last;
   end Add_Bottom;

   function Add_Atomic (Expr : in out Concept_Expression; C : Concept_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Atomic, Concept => C);
      return Expr.Last;
   end Add_Atomic;

   function Add_Intersection (Expr : in out Concept_Expression; L, R : Node_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Intersection, Left => L, Right => R);
      return Expr.Last;
   end Add_Intersection;

   function Add_Union (Expr : in out Concept_Expression; L, R : Node_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Union, Left => L, Right => R);
      return Expr.Last;
   end Add_Union;

   function Add_Negation (Expr : in out Concept_Expression; Op : Node_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Negation, Operand => Op);
      return Expr.Last;
   end Add_Negation;

   function Add_Universal (Expr : in out Concept_Expression; R : Role_ID; T : Node_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Universal, Role => R, Target => T);
      return Expr.Last;
   end Add_Universal;

   function Add_Existential (Expr : in out Concept_Expression; R : Role_ID; T : Node_ID) return Node_ID is
   begin
      if Expr.Last >= Max_Nodes then
         raise Expression_Full;
      end if;
      Expr.Last := Expr.Last + 1;
      Expr.Nodes (Expr.Last) := (Kind => Existential, Role => R, Target => T);
      return Expr.Last;
   end Add_Existential;

   -----------------------------------------------------------------------------
   -- Semantic Evaluation (Model Checking)
   -----------------------------------------------------------------------------

   function Evaluate (I : Interpretation; Expr : Concept_Expression; N : Node_ID) return Individual_Set is
      Result : Individual_Set := (others => False);
      L_Set, R_Set, T_Set : Individual_Set;
   begin
      if N > Expr.Last then
         raise Invalid_Node;
      end if;

      case Expr.Nodes (N).Kind is
         when Top =>
            for Idx in 1 .. I.Size loop
               Result (Idx) := True;
            end loop;

         when Bottom =>
            null; -- Initialization handles this (remains False)

         when Atomic =>
            for Idx in 1 .. I.Size loop
               Result (Idx) := I.Concepts (Expr.Nodes (N).Concept) (Idx);
            end loop;

         when Intersection =>
            L_Set := Evaluate (I, Expr, Expr.Nodes (N).Left);
            R_Set := Evaluate (I, Expr, Expr.Nodes (N).Right);
            for Idx in 1 .. I.Size loop
               Result (Idx) := L_Set (Idx) and R_Set (Idx);
            end loop;

         when Union =>
            L_Set := Evaluate (I, Expr, Expr.Nodes (N).Left);
            R_Set := Evaluate (I, Expr, Expr.Nodes (N).Right);
            for Idx in 1 .. I.Size loop
               Result (Idx) := L_Set (Idx) or R_Set (Idx);
            end loop;

         when Negation =>
            L_Set := Evaluate (I, Expr, Expr.Nodes (N).Operand);
            for Idx in 1 .. I.Size loop
               Result (Idx) := not L_Set (Idx);
            end loop;

         when Universal =>
            T_Set := Evaluate (I, Expr, Expr.Nodes (N).Target);
            for Idx in 1 .. I.Size loop
               Result (Idx) := True;
               for Y in 1 .. I.Size loop
                  if I.Roles (Expr.Nodes (N).Role) (Idx, Y) then
                     if not T_Set (Y) then
                        Result (Idx) := False;
                        exit;
                     end if;
                  end if;
               end loop;
            end loop;

         when Existential =>
            T_Set := Evaluate (I, Expr, Expr.Nodes (N).Target);
            for Idx in 1 .. I.Size loop
               for Y in 1 .. I.Size loop
                  if I.Roles (Expr.Nodes (N).Role) (Idx, Y) and then T_Set (Y) then
                     Result (Idx) := True;
                     exit;
                  end if;
               end loop;
            end loop;
      end case;

      return Result;
   end Evaluate;

   -----------------------------------------------------------------------------
   -- TBox Reasoning Tasks
   -----------------------------------------------------------------------------

   function Satisfies_Subsumption (I : Interpretation; Expr : Concept_Expression; Sub, Super : Node_ID) return Boolean is
      Sub_Set   : constant Individual_Set := Evaluate (I, Expr, Sub);
      Super_Set : constant Individual_Set := Evaluate (I, Expr, Super);
   begin
      for Idx in 1 .. I.Size loop
         if Sub_Set (Idx) and then not Super_Set (Idx) then
            return False;
         end if;
      end loop;
      return True;
   end Satisfies_Subsumption;

   function Satisfies_Equivalence (I : Interpretation; Expr : Concept_Expression; C, D : Node_ID) return Boolean is
      C_Set : constant Individual_Set := Evaluate (I, Expr, C);
      D_Set : constant Individual_Set := Evaluate (I, Expr, D);
   begin
      for Idx in 1 .. I.Size loop
         if C_Set (Idx) /= D_Set (Idx) then
            return False;
         end if;
      end loop;
      return True;
   end Satisfies_Equivalence;

   function Satisfies_Disjointness (I : Interpretation; Expr : Concept_Expression; C, D : Node_ID) return Boolean is
      C_Set : constant Individual_Set := Evaluate (I, Expr, C);
      D_Set : constant Individual_Set := Evaluate (I, Expr, D);
   begin
      for Idx in 1 .. I.Size loop
         if C_Set (Idx) and then D_Set (Idx) then
            return False;
         end if;
      end loop;
      return True;
   end Satisfies_Disjointness;

   -----------------------------------------------------------------------------
   -- ABox Reasoning Tasks
   -----------------------------------------------------------------------------

   function Satisfies_Concept_Assertion (I : Interpretation; Expr : Concept_Expression; Indiv : Individual_ID; C : Node_ID) return Boolean is
      C_Set : constant Individual_Set := Evaluate (I, Expr, C);
   begin
      if Indiv > I.Size then
         return False;
      end if;
      return C_Set (Indiv);
   end Satisfies_Concept_Assertion;

   function Satisfies_Role_Assertion (I : Interpretation; Indiv1, Indiv2 : Individual_ID; R : Role_ID) return Boolean is
   begin
      if Indiv1 > I.Size or else Indiv2 > I.Size then
         return False;
      end if;
      return I.Roles (R) (Indiv1, Indiv2);
   end Satisfies_Role_Assertion;

end Description_Logic;
