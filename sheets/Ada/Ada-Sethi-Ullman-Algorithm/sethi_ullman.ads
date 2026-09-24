-- sethi_ullman.ads
with Ada.Containers.Vectors;

package Sethi_Ullman is

   -- Node kinds for the Abstract Syntax Tree (AST)
   type Node_Kind is (Leaf_Node, Op_Node);
   
   -- Supported arithmetic operations
   type Op_Kind is (Op_Add, Op_Sub, Op_Mul, Op_Div);

   -- Machine architecture variants for the algorithm
   type Machine_Model is (
      Standard_Model, -- All leaves require 1 register to load (renamed to avoid collision with Ada.Standard)
      Memory_Operand  -- Right leaf can be operated directly from memory (requires 0 registers)
   );

   type AST_Node;
   type AST_Ptr is access AST_Node;

   -- Abstract Syntax Tree Definition
   type AST_Node (Kind : Node_Kind := Leaf_Node) is record
      Label : Natural := 0; -- Sethi-Ullman weight (register requirement)
      case Kind is
         when Leaf_Node =>
            Id : Positive; -- Represents a variable or immediate value identifier
         when Op_Node =>
            Op    : Op_Kind;
            Left  : AST_Ptr;
            Right : AST_Ptr;
      end case;
   end record;

   -- Instruction Set Architecture (ISA) Definitions
   type Instr_Op is (Load, Store, Add, Sub, Mul, Div, Load_Mem);
   
   type Operand_Type is (Reg, Mem, Imm);
   
   type Operand is record
      Kind  : Operand_Type;
      Value : Natural; -- Register ID, Memory Address, or Immediate Value
   end record;

   type Instruction is record
      Opcode : Instr_Op;
      Dest   : Operand;
      Src1   : Operand;
      Src2   : Operand;
   end record;

   -- Vector for storing generated instructions
   package Instr_Vectors is new Ada.Containers.Vectors 
     (Index_Type   => Positive, 
      Element_Type => Instruction);
      
   subtype Instr_List is Instr_Vectors.Vector;

   -- Exceptions
   Null_Tree_Error    : exception;
   Invalid_Node_Error : exception;

   -- Subprograms
   
   -- Phase 1: Labeling the AST (Calculates register needs)
   procedure Label_Tree 
     (Root    : AST_Ptr; 
      Model   : Machine_Model := Standard_Model; 
      Is_Left : Boolean := True);

   -- Variant: Optimizes AST by rearranging commutative operators (Add/Mul) to minimize registers
   procedure Optimize_Commutative (Root : AST_Ptr);

   -- Phase 2: Generates instructions (includes Spilling variant if Available_Reg is exceeded)
   procedure Generate_Code
     (Root          : AST_Ptr;
      Available_Reg : Positive;
      Instructions  : out Instr_List);

   -- Memory Management
   procedure Free_Tree (Root : in out AST_Ptr);

end Sethi_Ullman;
