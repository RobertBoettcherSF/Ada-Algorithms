package Self_Organizing_Map is

   -- Strong typing for algorithm-specific data
   type Data_Value is new Float;
   type Feature_Index is new Positive;
   type Sample_Index is new Positive;
   type Grid_X is new Positive;
   type Grid_Y is new Positive;

   -- Vectors and Matrices for SOM representation and Training Data
   type Vector is array (Feature_Index range <>) of Data_Value;
   type Dataset is array (Sample_Index range <>, Feature_Index range <>) of Data_Value;
   
   -- The SOM Grid is represented as a 3D matrix: X, Y coordinates and the feature depth
   type SOM_Map is array (Grid_X range <>, Grid_Y range <>, Feature_Index range <>) of Data_Value;

   type Coordinate is record
      X : Grid_X;
      Y : Grid_Y;
   end record;

   -- Named exceptions for algorithm edge cases
   Dimension_Mismatch : exception;
   Empty_Dataset      : exception;
   Invalid_Parameters : exception;

   -- 1. Initialize_Random: Initializes map weights with random values between 0.0 and 1.0
   procedure Initialize_Random
     (Map  : out SOM_Map;
      Seed : in  Integer)
     with Global => null;

   -- 2. Euclidean_Distance: Calculates the straight-line distance between two feature vectors
   function Euclidean_Distance (V1, V2 : Vector) return Data_Value
     with Pre   => V1'Length = V2'Length,
          Global => null;

   -- 3. Find_BMU: Returns the Best Matching Unit (the node with the minimum distance to Vec)
   function Find_BMU
     (Map : in SOM_Map;
      Vec : in Vector) return Coordinate
     with Pre   => Map'Length (1) > 0 
                   and then Map'Length (2) > 0 
                   and then Map'Length (3) = Vec'Length,
          Global => null;

   -- 4. Train_Online: Sequential / Incremental training variant.
   --    Updates the SOM weights after processing each individual sample.
   procedure Train_Online
     (Map                   : in out SOM_Map;
      Data                  : in     Dataset;
      Epochs                : in     Positive;
      Initial_Learning_Rate : in     Data_Value;
      Initial_Radius        : in     Data_Value)
     with Pre => Data'Length (1) > 0 
                 and then Data'Length (2) = Map'Length (3)
                 and then Initial_Learning_Rate > 0.0
                 and then Initial_Radius > 0.0;

   -- 5. Train_Batch: Batch training variant.
   --    Accumulates updates for the entire dataset per epoch, updating weights at the end.
   procedure Train_Batch
     (Map            : in out SOM_Map;
      Data           : in     Dataset;
      Epochs         : in     Positive;
      Initial_Radius : in     Data_Value)
     with Pre => Data'Length (1) > 0 
                 and then Data'Length (2) = Map'Length (3)
                 and then Initial_Radius > 0.0;

   -- 6. Extract_Vector: Helper to pull a specific node's weight vector from the 3D map
   function Extract_Vector (Map : SOM_Map; X : Grid_X; Y : Grid_Y) return Vector
     with Pre   => X in Map'Range(1) and then Y in Map'Range(2),
          Global => null;

   -- 7. Extract_Sample: Helper to pull a 1D sample row from a 2D Dataset matrix
   function Extract_Sample (Data : Dataset; Row : Sample_Index) return Vector
     with Pre   => Row in Data'Range(1),
          Global => null;

end Self_Organizing_Map;
