with Ada.Strings.Unbounded;

package Rete is
   pragma Elaborate_Body;

   -- =========================================================================
   -- Strong Typing & Algorithm-Specific Data
   -- =========================================================================

   -- Symbols represent strings in Working Memory and Network tests
   type Symbol is private;
   function To_Symbol (S : String) return Symbol;
   function To_String (S : Symbol) return String;
   function "=" (Left, Right : Symbol) return Boolean;
   function Empty_Symbol return Symbol;

   type WME_ID is new Natural;
   Null_WME_ID : constant WME_ID := 0;

   -- Working Memory Element (Fact)
   type WME is record
      ID        : WME_ID;
      Entity    : Symbol;
      Attribute : Symbol;
      Value     : Symbol;
   end record;

   -- Field Selectors for Join Conditions at Beta Nodes
   type Field_Selector is (Select_Entity, Select_Attribute, Select_Value);

   -- Condition mapping a field from a token's WME to a field in an Alpha WME
   type Join_Condition is record
      Left_Token_Index : Natural; -- 0 means no condition (Cross Join)
      Left_Field       : Field_Selector;
      Right_Field      : Field_Selector;
   end record;

   -- Node Identifiers for Network Configuration
   Max_Nodes : constant := 100;
   type Alpha_Node_ID is new Natural range 0 .. Max_Nodes;
   type Beta_Node_ID is new Natural range 0 .. Max_Nodes;
   type Rule_ID is new Natural range 0 .. Max_Nodes;

   -- Algorithm Exceptions
   Network_Full   : exception;
   Duplicate_ID   : exception;
   Fact_Not_Found : exception;

   -- Token representing a partial match sequence
   type Token is private;
   function Get_Token_Size (T : Token) return Natural;
   function Get_Token_Element (T : Token; Index : Positive) return WME;

   -- =========================================================================
   -- Rete Network Configuration (Static Phase)
   -- =========================================================================

   -- Clears network and memories
   procedure Initialize_Network;

   -- Adds an Alpha Node filtering by Attribute and Value
   function Add_Alpha_Node (Attribute : Symbol; Value : Symbol) return Alpha_Node_ID
     with Pre  => Attribute /= Empty_Symbol and Value /= Empty_Symbol,
          Post => Add_Alpha_Node'Result > 0 and Add_Alpha_Node'Result <= Max_Nodes;

   -- Adds a Beta Node joining a previous Beta Node's output with an Alpha Node
   -- Parent_Beta = 0 implicitly connects to the Root node (empty token)
   function Add_Beta_Node (
      Parent_Beta  : Beta_Node_ID;
      Parent_Alpha : Alpha_Node_ID;
      Condition    : Join_Condition
   ) return Beta_Node_ID
     with Pre  => Parent_Alpha > 0,
          Post => Add_Beta_Node'Result > 0 and Add_Beta_Node'Result <= Max_Nodes;

   -- Associates a named rule with a terminal Beta Node
   procedure Add_Rule (ID : Rule_ID; Name : Symbol; Beta : Beta_Node_ID)
     with Pre => ID > 0 and Beta > 0;

   -- =========================================================================
   -- Operational Variants (Dynamic Phase)
   -- =========================================================================

   -- Variant 1: Standard Incremental Insertion
   -- Percolates a WME through Alpha then Beta networks
   procedure Insert_WME (Fact : WME)
     with Pre => Fact.ID > 0;

   -- Variant 2: Batched Insertion
   type WME_Array is array (Positive range <>) of WME;
   procedure Insert_WME_Batched (Facts : WME_Array);

   -- Variant 3: State-Sweep Retraction
   -- Cleans matching WMEs from Alpha memories and sweeps Beta tokens
   procedure Remove_WME (ID : WME_ID)
     with Pre => ID > 0;

   -- =========================================================================
   -- Inspection & Validation API
   -- =========================================================================

   function Get_Global_WM_Count return Natural;
   function Get_Alpha_Match_Count (Alpha : Alpha_Node_ID) return Natural;
   function Get_Beta_Match_Count (Beta : Beta_Node_ID) return Natural;
   function Get_Rule_Match_Count (Rule : Rule_ID) return Natural;

private
   use Ada.Strings.Unbounded;

   type Symbol is record
      Value : Unbounded_String;
   end record;

   Max_WMEs_Per_Token : constant := 8;
   type WME_Array_Internal is array (1 .. Max_WMEs_Per_Token) of WME;

   type Token is record
      Size     : Natural := 0;
      Elements : WME_Array_Internal;
   end record;

end Rete;
