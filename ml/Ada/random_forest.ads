package Random_Forest
  with SPARK_Mode => Off
is
   -- Strong typing for algorithm-specific data
   type Feature_Value is new Float;
   type Target_Value is new Float;
   type Class_Label is new Integer range -10_000 .. 10_000;

   type Feature_Vector is array (Positive range <>) of Feature_Value;
   type Matrix is array (Positive range <>, Positive range <>) of Feature_Value;

   type Class_Array is array (Positive range <>) of Class_Label;
   type Target_Array is array (Positive range <>) of Target_Value;

   -- Random Forest variants supported
   type Forest_Variant is (Standard_Random_Forest, Extra_Trees);

   -----------------------------------------------------------------------------
   -- Classification Forest
   -----------------------------------------------------------------------------
   type Classification_Forest (Num_Trees : Positive) is private;

   function Train_Classifier
     (Data      : Matrix;
      Labels    : Class_Array;
      Num_Trees : Positive;
      Max_Depth : Positive;
      Variant   : Forest_Variant := Standard_Random_Forest) return Classification_Forest
     with Pre => Data'Length (1) > 0
                 and then Data'Length (2) > 0
                 and then Data'Length (1) = Labels'Length,
          Post => Train_Classifier'Result.Num_Trees = Num_Trees,
          Global => null;

   function Predict_Class
     (Forest : Classification_Forest;
      Sample : Feature_Vector) return Class_Label
     with Pre => Sample'Length > 0,
          Global => null;

   -----------------------------------------------------------------------------
   -- Regression Forest
   -----------------------------------------------------------------------------
   type Regression_Forest (Num_Trees : Positive) is private;

   function Train_Regressor
     (Data      : Matrix;
      Targets   : Target_Array;
      Num_Trees : Positive;
      Max_Depth : Positive;
      Variant   : Forest_Variant := Standard_Random_Forest) return Regression_Forest
     with Pre => Data'Length (1) > 0
                 and then Data'Length (2) > 0
                 and then Data'Length (1) = Targets'Length,
          Post => Train_Regressor'Result.Num_Trees = Num_Trees,
          Global => null;

   function Predict_Value
     (Forest : Regression_Forest;
      Sample : Feature_Vector) return Target_Value
     with Pre => Sample'Length > 0,
          Global => null;

private
   Max_Nodes_Per_Tree : constant Positive := 4095;

   type Node is record
      Is_Leaf     : Boolean := True;
      Feature_Idx : Positive := 1;
      Threshold   : Feature_Value := 0.0;
      Left_Child  : Natural := 0;
      Right_Child : Natural := 0;
      Class_Pred  : Class_Label := 0;
      Value_Pred  : Target_Value := 0.0;
   end record;

   type Node_Array is array (Positive range 1 .. Max_Nodes_Per_Tree) of Node;

   type Decision_Tree is record
      Nodes : Node_Array;
      Count : Natural := 0;
   end record;

   type Tree_Array is array (Positive range <>) of Decision_Tree;

   type Base_Forest (Num_Trees : Positive) is record
      Trees : Tree_Array (1 .. Num_Trees);
   end record;

   type Classification_Forest (Num_Trees : Positive) is new Base_Forest (Num_Trees => Num_Trees);
   type Regression_Forest (Num_Trees : Positive) is new Base_Forest (Num_Trees => Num_Trees);

end Random_Forest;
