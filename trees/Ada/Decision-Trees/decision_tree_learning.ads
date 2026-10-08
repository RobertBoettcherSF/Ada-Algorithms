pragma Ada_2022;

package Decision_Tree_Learning is

   -- Core domain types to ensure strong typing
   type Feature_Index is new Positive;
   type Instance_Index is new Positive;

   type Feature_Value is new Float;
   type Class_Label is new Positive;

   -- Arrays for features and dataset definitions
   type Feature_Array is array (Feature_Index range <>) of Feature_Value;
   type Feature_Matrix is array (Instance_Index range <>, Feature_Index range <>) of Feature_Value;
   type Label_Vector is array (Instance_Index range <>) of Class_Label;

   -- Split criterion metric to choose between ID3-style and CART-style
   type Split_Criterion is (Gini_Impurity, Information_Gain);

   -- Tree node structures
   type Node_Kind is (Leaf, Split);

   type Tree_Node;
   type Tree_Node_Access is access Tree_Node;

   type Tree_Node (Kind : Node_Kind := Leaf) is record
      case Kind is
         when Leaf =>
            Prediction : Class_Label;
         when Split =>
            Split_Feature : Feature_Index;
            Split_Value   : Feature_Value;
            Left_Child    : Tree_Node_Access;
            Right_Child   : Tree_Node_Access;
      end case;
   end record;

   -- Named exceptions for edge cases and errors
   Empty_Dataset_Error         : exception;
   Mismatched_Dimensions_Error : exception;
   Null_Tree_Error             : exception;
   Invalid_Feature_Error       : exception;

   -- Core Subprograms

   -- Main training routine supporting depth limits and min samples threshold.
   function Train
     (X                 : Feature_Matrix;
      Y                 : Label_Vector;
      Criterion         : Split_Criterion := Gini_Impurity;
      Max_Depth         : Natural := 10;
      Min_Samples_Split : Positive := 2) return Tree_Node_Access
     with Post => Train'Result /= null;

   -- Predicts the target class given an instance feature array.
   function Predict
     (Tree : Tree_Node_Access;
      X    : Feature_Array) return Class_Label;

   -- Frees allocated memory for the decision tree.
   procedure Free_Tree (Tree : in out Tree_Node_Access);

   -- Variant subprograms per algorithm specifics

   -- Implements the ID3 variant concept using Information Gain (Entropy).
   function Train_ID3_Variant
     (X         : Feature_Matrix;
      Y         : Label_Vector;
      Max_Depth : Natural := 10) return Tree_Node_Access;

   -- Implements the CART variant concept using Gini Impurity.
   function Train_CART_Variant
     (X         : Feature_Matrix;
      Y         : Label_Vector;
      Max_Depth : Natural := 10) return Tree_Node_Access;

end Decision_Tree_Learning;
