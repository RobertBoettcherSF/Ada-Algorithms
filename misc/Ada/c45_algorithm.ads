--  The C45_Algorithm package implements the core components of the C4.5
--  decision tree classifier, including handling of discrete and continuous
--  attributes, missing values, and tree pruning.
package C45_Algorithm is

   --  Strong typing for all algorithm-specific data to prevent domain mixing.
   type Class_Label is new Natural range 0 .. 10_000;
   
   --  Constrain attributes to a reasonable maximum for stack safety and definite types
   Max_Attributes : constant := 10;
   type Attribute_Index is new Positive range 1 .. Max_Attributes;
   
   type Attribute_Value is new Float;

   --  Sentinel value for representing missing data in the dataset.
   Missing_Value : constant Attribute_Value := Attribute_Value'First;

   type Attribute_Kind is (Discrete, Continuous);

   --  Defines the schema of a single attribute.
   type Attribute_Definition is record
      Kind               : Attribute_Kind;
      --  For discrete attributes, valid values are 1.0 .. Float (Max_Discrete_Value)
      Max_Discrete_Value : Positive;
   end record;

   type Attribute_Set is array (Attribute_Index range <>) of Attribute_Definition;
   
   --  Constrained array size so it can be safely used inside a record
   type Value_Array is array (Attribute_Index) of Attribute_Value;

   --  A single training or testing instance.
   type Instance is record
      Features : Value_Array;
      Class    : Class_Label;
   end record;

   type Dataset is array (Positive range <>) of Instance;

   --  Exceptions raised by the package for invalid inputs.
   Invalid_Dataset : exception;
   Tree_Error      : exception;

   --  Opaque pointer for the decision tree to hide implementation details.
   type Decision_Tree is private;

   --  Helper to check if a private tree pointer is unallocated or null
   function Is_Null (Tree : Decision_Tree) return Boolean;

   --  ========================================================================
   --  Variant 1: Standard C4.5 Tree Construction
   --  Builds a full decision tree using Information Gain Ratio.
   --  ========================================================================
   function Build_Tree
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
     with Pre => Data'Length > 0 and Attrs'Length > 0;

   --  ========================================================================
   --  Variant 2: C4.5 Tree Construction with Post-Pruning
   --  Builds a full tree, then performs bottom-up reduced-error pruning to
   --  collapse redundant branches into leaf nodes.
   --  ========================================================================
   function Build_Tree_Pruned
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
     with Pre => Data'Length > 0 and Attrs'Length > 0;

   --  ========================================================================
   --  Variant 3: C4.5 Tree Construction Handling Missing Values
   --  Routes instances with Missing_Value to the most probable branch.
   --  ========================================================================
   function Build_Tree_Handle_Missing
     (Data  : Dataset;
      Attrs : Attribute_Set) return Decision_Tree
     with Pre => Data'Length > 0 and Attrs'Length > 0;

   --  ========================================================================
   --  Classification
   --  Evaluates a feature set against a built decision tree.
   --  ========================================================================
   function Classify
     (Tree     : Decision_Tree;
      Features : Value_Array) return Class_Label
     with Pre => not Is_Null (Tree);

   --  ========================================================================
   --  Helper Functions (Exposed for robust unit testing)
   --  ========================================================================
   function Calculate_Entropy (Data : Dataset) return Float
     with Pre => Data'Length > 0,
          Post => Calculate_Entropy'Result >= 0.0;

   --  Recursively frees all memory associated with the decision tree.
   procedure Destroy_Tree (Tree : in out Decision_Tree);

private
   type Node_Kind is (Leaf, Continuous_Split, Discrete_Split);
   type Decision_Tree_Node;
   type Decision_Tree is access Decision_Tree_Node;
   type Children_Array is array (Positive range <>) of Decision_Tree;
   type Children_Access is access Children_Array;

   type Decision_Tree_Node (Kind : Node_Kind) is record
      case Kind is
         when Leaf =>
            Predicted_Class : Class_Label;
         when Continuous_Split =>
            Attr_Index_C    : Attribute_Index;
            Threshold       : Attribute_Value;
            Left_Child      : Decision_Tree;
            Right_Child     : Decision_Tree;
         when Discrete_Split =>
            Attr_Index_D    : Attribute_Index;
            Children        : Children_Access;
      end case;
   end record;

end C45_Algorithm;
