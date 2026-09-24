pragma Ada_2022;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Ordered_Sets;
with Ada.Containers.Ordered_Maps;

package ID3 is

   -- Domain-specific types to enforce strong typing
   type Attribute_Index is new Natural;
   subtype Attribute_ID is Attribute_Index range 1 .. Attribute_Index'Last;
   type Value_ID is new Natural;
   type Class_ID is new Natural;
   type Metric_Value is new Float;

   -- Instances and Dataset representation
   type Attribute_Array is array (Attribute_ID range <>) of Value_ID;

   type Instance (Num_Attributes : Attribute_Index) is record
      Attributes : Attribute_Array (1 .. Num_Attributes);
      Class      : Class_ID;
   end record;

   package Instance_Vectors is new Ada.Containers.Indefinite_Vectors
     (Index_Type   => Positive,
      Element_Type => Instance);
   subtype Dataset is Instance_Vectors.Vector;

   -- Sets for tracking available attributes during tree generation
   package Attribute_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => Attribute_ID);
   subtype Attribute_Set is Attribute_Sets.Set;

   -- Tree structural types
   type Node_Kind is (Leaf, Decision);

   type Tree_Node (Kind : Node_Kind);
   type Tree is access Tree_Node;

   package Value_Tree_Maps is new Ada.Containers.Ordered_Maps
     (Key_Type     => Value_ID,
      Element_Type => Tree);
   subtype Value_Tree_Map is Value_Tree_Maps.Map;

   type Tree_Node (Kind : Node_Kind) is record
      case Kind is
         when Leaf =>
            Predicted_Class : Class_ID;
         when Decision =>
            Attribute     : Attribute_ID;
            Branches      : Value_Tree_Map;
            Default_Class : Class_ID; -- Fallback for values unseen in training
      end case;
   end record;

   -- Named exceptions for edge cases and validation failures
   Empty_Dataset_Error : exception;
   Invalid_Data_Error  : exception;
   Prediction_Error    : exception;

   -- Available ID3 splitting variants
   type Split_Criterion is (Use_Information_Gain, Use_Gain_Ratio);

   -- Core ID3 algorithms and metrics
   function Entropy (Data : Dataset) return Metric_Value
     with Pre => not Data.Is_Empty;

   function Information_Gain (Data : Dataset; Attr : Attribute_ID) return Metric_Value
     with Pre => not Data.Is_Empty;

   function Gain_Ratio (Data : Dataset; Attr : Attribute_ID) return Metric_Value
     with Pre => not Data.Is_Empty;

   function Build_Tree
     (Data       : Dataset;
      Attributes : Attribute_Set;
      Criterion  : Split_Criterion := Use_Information_Gain) return Tree
     with Pre => not Data.Is_Empty;

   function Predict (Model : Tree; Inst : Instance) return Class_ID
     with Pre => Model /= null;

   -- Memory management
   procedure Free_Tree (T : in out Tree);

end ID3;
