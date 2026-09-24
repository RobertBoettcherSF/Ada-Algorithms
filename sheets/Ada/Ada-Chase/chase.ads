--  chase.ads
--  Implementation of the Chase algorithm for database functional dependencies
--  and its variants (Oblivious, Restricted, Core)

package Chase is

   -- ===================================================================
   -- TYPE DEFINITIONS
   -- ===================================================================

   -- Attribute names are represented as single characters (A, B, C, D, etc.)
   type Attribute is (Nul, A, B, C, D, E, F, G, H);

   -- A value in the tableau can be either a literal (unsubscripted) or a variable (subscripted)
   type Value_Kind is (Literal_Value, Variable_Value);

   type Value is record
      Text     : String(1..10);  -- Value text (e.g., "a", "b1", etc.)
      V_Kind   : Value_Kind;
      Subscript : Integer;         -- For variables: the subscript (0 = no subscript)
   end record;

   -- Maximum dimensions for practical use
   Max_Attributes : constant Integer := 20;
   Max_Tuples : constant Integer := 100;
   Max_FDs : constant Integer := 50;
   Max_Schemas : constant Integer := 20;

   -- A tuple in the tableau
   type Tuple is array (1..Max_Attributes) of Value;

   -- A relation schema (set of attributes)
   type Attribute_List is array (1..Max_Attributes) of Attribute;

   -- A functional dependency: Left -> Right
   type Functional_Dependency is record
      Left : Attribute_List;
      Left_Length : Integer;
      Right : Attribute;
   end record;

   -- Set of functional dependencies
   type FD_List is array (1..Max_FDs) of Functional_Dependency;

   -- A tableau (matrix of values)
   type Tableau is array (1..Max_Tuples) of Tuple;

   -- A decomposition (set of relation schemas)
   type Decomposition is array (1..Max_Schemas) of Attribute_List;

   -- ===================================================================
   -- EXCEPTIONS
   -- ===================================================================

   Attribute_Not_Found : exception;
   Empty_Tableau : exception;
   Invalid_FD : exception;
   Invalid_Decomposition : exception;

   -- ===================================================================
   -- MAIN CHASE ALGORITHMS
   -- ===================================================================

   function Standard_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean;

   function Oblivious_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean;

   function Core_Chase (
      Original_Tuple : Tuple;
      FDs : FD_List;
      FDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean;

   function Restricted_Chase_TGD (
      Original_Tuple : Tuple;
      TGDs : FD_List;
      TGDs_Length : Integer;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer)
   return Boolean;

   -- ===================================================================
   -- TABLEAU OPERATIONS
   -- ===================================================================

   procedure Create_Initial_Tableau (
      Original_Tuple : Tuple;
      Decomp : Decomposition;
      Decomp_Length : Integer;
      Tuple_Length : Integer;
      Result : out Tableau;
      Result_Length : out Integer);

   procedure Apply_FD (
      T : in out Tableau;
      T_Length : Integer;
      FD : Functional_Dependency;
      Tuple_Length : Integer;
      Changed : out Boolean);

   function Contains_Original_Tuple (
      T : Tableau;
      T_Length : Integer;
      Original_Tuple : Tuple;
      Tuple_Length : Integer)
   return Boolean;

   function Values_Equal (Left, Right : Value) return Boolean;

   -- ===================================================================
   -- HELPER FUNCTIONS
   -- ===================================================================

   function Char_To_Attribute (C : Character) return Attribute;

   function Create_Literal (Text : String) return Value;
   function Create_Variable (Text : String; Subscript : Integer) return Value;

   function Find_Attribute_Index (
      Attributes : Attribute_List;
      Attr_Length : Integer;
      Attr : Attribute)
   return Integer;

   function Attribute_In_Schema (
      Attributes : Attribute_List;
      Attr_Length : Integer;
      Attr : Attribute)
   return Boolean;

   -- ===================================================================
   -- VALIDATION FUNCTIONS
   -- ===================================================================

   function Validate_FDs (FDs : FD_List; FDs_Length : Integer) return Boolean;

   function Validate_Decomposition (
      Decomp : Decomposition;
      Decomp_Length : Integer;
      All_Attrs : Attribute_List;
      All_Attrs_Length : Integer)
   return Boolean;

end Chase;
