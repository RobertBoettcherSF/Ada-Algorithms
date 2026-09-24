package One_Attribute_Rule is
   pragma Preelaborate;

   -- Domain-specific types for strong typing
   type Attribute_Index is new Positive;
   type Attribute_Value is new Integer;
   type Class_Label     is new Integer;

   type Attribute_Array is array (Attribute_Index range <>) of Attribute_Value;
   type Class_Array     is array (Positive range <>) of Class_Label;

   type Dataset_Grid is array (Positive range <>, Attribute_Index range <>) of Attribute_Value;

   -- Represents a set of instances and their corresponding target classes
   type Dataset (Num_Instances : Natural; Num_Attributes : Attribute_Index) is record
      Grid    : Dataset_Grid (1 .. Num_Instances, 1 .. Num_Attributes);
      Classes : Class_Array (1 .. Num_Instances);
   end record;

   -- Exceptions for error handling
   Invalid_Dataset_Error : exception;
   Unseen_Value_Error    : exception;

   -- Maps a specific attribute value to the predicted class label
   type Value_Rule is record
      Value : Attribute_Value;
      Class : Class_Label;
   end record;

   type Value_Rule_Array is array (Positive range <>) of Value_Rule;

   -- Variant 1: Basic Model 
   -- Raises Unseen_Value_Error if asked to predict on an unobserved attribute value.
   type Basic_Model (Num_Rules : Natural) is record
      Best_Attribute : Attribute_Index;
      Rules          : Value_Rule_Array (1 .. Num_Rules);
      Total_Error    : Natural;
   end record;

   -- Variant 2: Robust Model
   -- Returns a dynamically calculated Default_Class if a value wasn't seen in training.
   type Robust_Model (Num_Rules : Natural) is record
      Best_Attribute : Attribute_Index;
      Rules          : Value_Rule_Array (1 .. Num_Rules);
      Total_Error    : Natural;
      Default_Class  : Class_Label;
   end record;

   -- Trains a strict One-Attribute Rule model
   function Train_Basic (Data : Dataset) return Basic_Model
     with Pre => Data.Num_Instances > 0;

   -- Predicts a class for a new instance using the strict model
   function Predict_Basic (Model : Basic_Model; Attrs : Attribute_Array) return Class_Label
     with Pre => Model.Num_Rules > 0 and then
                 Attrs'First <= Model.Best_Attribute and then
                 Attrs'Last >= Model.Best_Attribute;

   -- Trains a robust model that dynamically resolves unknown values to the global majority class
   function Train_Robust (Data : Dataset) return Robust_Model
     with Pre => Data.Num_Instances > 0;

   -- Predicts a class for a new instance using the robust fallback rules
   function Predict_Robust (Model : Robust_Model; Attrs : Attribute_Array) return Class_Label
     with Pre => Model.Num_Rules > 0 and then
                 Attrs'First <= Model.Best_Attribute and then
                 Attrs'Last >= Model.Best_Attribute;

end One_Attribute_Rule;
