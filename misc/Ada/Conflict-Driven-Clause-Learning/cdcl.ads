with Ada.Containers.Vectors;

package CDCL is
   pragma Preelaborate;

   type Variable_Id is new Positive;
   type Literal is new Integer;
   subtype Clause_Index is Positive;

   type Truth_Value is (False, True, Unassigned);

   package Literal_Vectors is new Ada.Containers.Vectors (Positive, Literal);
   subtype Clause is Literal_Vectors.Vector;

   package Clause_Vectors is new Ada.Containers.Vectors (
      Index_Type   => Positive,
      Element_Type => Clause,
      "="          => Literal_Vectors."="
   );

   type Formula is record
      Variables_Count : Natural := 0;
      Clauses         : Clause_Vectors.Vector;
   end record;

   -- Exceptions
   Invalid_Formula : exception;
   Bad_Literal     : exception;

   -- API
   procedure Init_Formula (F : out Formula; Vars : Natural);
   procedure Add_Clause (F : in out Formula; C : Clause);

   type Solve_Status is (Satisfiable, Unsatisfiable, Unknown);
   type Assignment_Array is array (Variable_Id range <>) of Truth_Value;

   -- Variant 1: Basic CDCL
   function Solve_Basic (F : Formula; Assignments : out Assignment_Array) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Variant 2: CDCL with Restarts
   function Solve_With_Restarts (F : Formula; Assignments : out Assignment_Array; Restart_Interval : Positive) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Variant 3: CDCL with Clause Deletion
   function Solve_With_Clause_Deletion (F : Formula; Assignments : out Assignment_Array; Max_Learned : Positive) return Solve_Status
     with Pre => F.Variables_Count > 0 and then Assignments'Length = F.Variables_Count;

   -- Helper: to validate an assignment against a formula
   function Is_Satisfied (F : Formula; Assignments : Assignment_Array) return Boolean;

end CDCL;
