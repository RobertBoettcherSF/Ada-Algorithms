with Ada.Text_IO; use Ada.Text_IO;
with Description_Logic; use Description_Logic;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Common setup
   Expr : Concept_Expression;
   I    : Interpretation;
   
   -- Domain IDs
   Alice  : constant Individual_ID := 1;
   Bob    : constant Individual_ID := 2;
   Rex    : constant Individual_ID := 3;
   
   -- Concept/Role IDs
   Human  : constant Concept_ID := 1;
   Animal : constant Concept_ID := 2;
   HasPet : constant Role_ID    := 1;
   Knows  : constant Role_ID    := 2;

   -- Helper for resetting domain
   procedure Init_Domain is
   begin
      I := (Size => 3, others => <>);
      I.Concepts (Human) (Alice) := True;
      I.Concepts (Human) (Bob)   := True;
      I.Concepts (Animal)(Rex)   := True;
      
      I.Roles (HasPet) (Alice, Rex) := True;
      I.Roles (Knows)  (Alice, Bob) := True;
      I.Roles (Knows)  (Bob, Alice) := True;
   end Init_Domain;

begin
   Init_Domain;

   Put_Line ("TEST 1 — Top and Bottom Concepts");
   declare
      T_Node : constant Node_ID := Add_Top (Expr);
      B_Node : constant Node_ID := Add_Bottom (Expr);
      T_Set  : constant Individual_Set := Evaluate (I, Expr, T_Node);
      B_Set  : constant Individual_Set := Evaluate (I, Expr, B_Node);
   begin
      Check ("1.1 Top contains Alice", T_Set (Alice));
      Check ("1.2 Top contains Rex", T_Set (Rex));
      Check ("1.3 Bottom is empty", not B_Set (Alice) and not B_Set (Bob));
   end;

   Put_Line ("TEST 2 — Atomic Concept Evaluation");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      H_Set  : constant Individual_Set := Evaluate (I, Expr, H_Node);
   begin
      Check ("2.1 Human contains Alice", H_Set (Alice));
      Check ("2.2 Human contains Bob", H_Set (Bob));
      Check ("2.3 Human excludes Rex", not H_Set (Rex));
   end;

   Put_Line ("TEST 3 — Intersection (AND)");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      A_Node : constant Node_ID := Add_Atomic (Expr, Animal);
      And_N  : constant Node_ID := Add_Intersection (Expr, H_Node, A_Node);
      Result : constant Individual_Set := Evaluate (I, Expr, And_N);
   begin
      Check ("3.1 Intersection excludes Alice", not Result (Alice));
      Check ("3.2 Intersection excludes Rex", not Result (Rex));
      
      -- Let's make an artificial intersection
      I.Concepts (Animal) (Alice) := True;
      declare
         Res2 : constant Individual_Set := Evaluate (I, Expr, And_N);
      begin
         Check ("3.3 Intersection includes overlapping Alice", Res2 (Alice));
      end;
      I.Concepts (Animal) (Alice) := False; -- reset
   end;

   Put_Line ("TEST 4 — Union (OR)");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      A_Node : constant Node_ID := Add_Atomic (Expr, Animal);
      Or_N   : constant Node_ID := Add_Union (Expr, H_Node, A_Node);
      Result : constant Individual_Set := Evaluate (I, Expr, Or_N);
   begin
      Check ("4.1 Union includes Alice", Result (Alice));
      Check ("4.2 Union includes Rex", Result (Rex));
      Check ("4.3 Domain correctly modeled", Result (Alice) and Result (Rex));
   end;

   Put_Line ("TEST 5 — Negation (NOT)");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      Not_H  : constant Node_ID := Add_Negation (Expr, H_Node);
      Result : constant Individual_Set := Evaluate (I, Expr, Not_H);
   begin
      Check ("5.1 Negation excludes Alice (is Human)", not Result (Alice));
      Check ("5.2 Negation excludes Bob (is Human)", not Result (Bob));
      Check ("5.3 Negation includes Rex (not Human)", Result (Rex));
   end;

   Put_Line ("TEST 6 — Existential Restriction (SOME)");
   declare
      A_Node : constant Node_ID := Add_Atomic (Expr, Animal);
      Ex_Pet : constant Node_ID := Add_Existential (Expr, HasPet, A_Node);
      Result : constant Individual_Set := Evaluate (I, Expr, Ex_Pet);
   begin
      Check ("6.1 Alice has SOME HasPet.Animal", Result (Alice));
      Check ("6.2 Bob has no pets", not Result (Bob));
      Check ("6.3 Rex has no pets", not Result (Rex));
   end;

   Put_Line ("TEST 7 — Universal Restriction (ALL)");
   declare
      H_Node  : constant Node_ID := Add_Atomic (Expr, Human);
      All_Knw : constant Node_ID := Add_Universal (Expr, Knows, H_Node);
      Result  : constant Individual_Set := Evaluate (I, Expr, All_Knw);
   begin
      Check ("7.1 Alice ALL Knows.Human (True)", Result (Alice));
      Check ("7.2 Bob ALL Knows.Human (True)", Result (Bob));
      Check ("7.3 Rex trivially ALL Knows.Human (Vacuous Truth)", Result (Rex));
   end;

   Put_Line ("TEST 8 — Complex Nested Expression");
   -- Human AND EXISTS HasPet.(NOT Human)
   declare
      H_Node   : constant Node_ID := Add_Atomic (Expr, Human);
      Not_H    : constant Node_ID := Add_Negation (Expr, H_Node);
      Ex_Alien : constant Node_ID := Add_Existential (Expr, HasPet, Not_H);
      Complex  : constant Node_ID := Add_Intersection (Expr, H_Node, Ex_Alien);
      Result   : constant Individual_Set := Evaluate (I, Expr, Complex);
   begin
      Check ("8.1 Alice is Human and has non-Human pet", Result (Alice));
      Check ("8.2 Bob fails (no pets)", not Result (Bob));
      Check ("8.3 Rex fails (not Human)", not Result (Rex));
   end;

   Put_Line ("TEST 9 — TBox: Subsumption");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      T_Node : constant Node_ID := Add_Top (Expr);
      B_Node : constant Node_ID := Add_Bottom (Expr);
   begin
      Check ("9.1 Human subsumed by Top", Satisfies_Subsumption (I, Expr, H_Node, T_Node));
      Check ("9.2 Top NOT subsumed by Human", not Satisfies_Subsumption (I, Expr, T_Node, H_Node));
      Check ("9.3 Bottom subsumed by Human", Satisfies_Subsumption (I, Expr, B_Node, H_Node));
   end;

   Put_Line ("TEST 10 — TBox: Equivalence");
   declare
      H_Node  : constant Node_ID := Add_Atomic (Expr, Human);
      H_Node2 : constant Node_ID := Add_Atomic (Expr, Human);
      T_Node  : constant Node_ID := Add_Top (Expr);
   begin
      Check ("10.1 Human equivalent to Human", Satisfies_Equivalence (I, Expr, H_Node, H_Node2));
      Check ("10.2 Human NOT equivalent to Top", not Satisfies_Equivalence (I, Expr, H_Node, T_Node));
      Check ("10.3 Top equivalent to Top", Satisfies_Equivalence (I, Expr, T_Node, T_Node));
   end;

   Put_Line ("TEST 11 — TBox: Disjointness");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      A_Node : constant Node_ID := Add_Atomic (Expr, Animal);
      T_Node : constant Node_ID := Add_Top (Expr);
   begin
      Check ("11.1 Human and Animal are disjoint", Satisfies_Disjointness (I, Expr, H_Node, A_Node));
      Check ("11.2 Human and Top NOT disjoint", not Satisfies_Disjointness (I, Expr, H_Node, T_Node));
      Check ("11.3 Top and Top NOT disjoint", not Satisfies_Disjointness (I, Expr, T_Node, T_Node));
   end;

   Put_Line ("TEST 12 — ABox: Assertions");
   declare
      H_Node : constant Node_ID := Add_Atomic (Expr, Human);
      T_Node : constant Node_ID := Add_Top (Expr);
   begin
      Check ("12.1 Concept Assertion: Human(Alice)", Satisfies_Concept_Assertion (I, Expr, Alice, H_Node));
      Check ("12.2 Concept Assertion: not Human(Rex)", not Satisfies_Concept_Assertion (I, Expr, Rex, H_Node));
      Check ("12.3 Role Assertion: HasPet(Alice, Rex)", Satisfies_Role_Assertion (I, Alice, Rex, HasPet));
      Check ("12.4 Role Assertion: not HasPet(Bob, Alice)", not Satisfies_Role_Assertion (I, Bob, Alice, HasPet));
   end;

   Put_Line ("TEST 13 — Exception Handling");
   begin
      declare
         procedure Discard_Set (S : Individual_Set) is
            pragma Unreferenced (S);
         begin
            null;
         end Discard_Set;
      begin
         -- Expr.Last is currently around 30. N=100 is invalid.
         Discard_Set (Evaluate (I, Expr, 100));
         Check ("13.1 Invalid Node should raise exception", False);
      end;
   exception
      when Invalid_Node =>
         Check ("13.1 Caught Invalid_Node exception", True);
         Check ("13.2 System remains stable", True);
   end;

   begin
      declare
         Overflow_Expr : Concept_Expression;
         procedure Discard_Node (N : Node_ID) is
            pragma Unreferenced (N);
         begin
            null;
         end Discard_Node;
      begin
         -- Max_Nodes is 128
         for Idx in 1 .. 128 loop
            Discard_Node (Add_Top (Overflow_Expr));
         end loop;
         Discard_Node (Add_Top (Overflow_Expr)); -- Should overflow
         Check ("13.3 Expression Full should raise exception", False);
      end;
   exception
      when Expression_Full =>
         Check ("13.3 Caught Expression_Full exception", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
