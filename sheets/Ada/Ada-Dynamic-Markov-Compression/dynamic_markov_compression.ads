with Ada.Containers.Vectors;

package Dynamic_Markov_Compression is

   -- Core Types for DMC
   type Bit is range 0 .. 1;
   
   -- Bounded to prevent Ada.Containers.Vectors Count_Type overflow
   type State_ID is new Integer range -1 .. 10_000_000;
   Null_State : constant State_ID := -1;

   -- Vector instantiation requires a non-negative start index
   subtype Node_Index is State_ID range 0 .. State_ID'Last;

   type Bit_Array is array (Bit) of State_ID;
   type Count_Array is array (Bit) of Natural;

   -- A Node represents a state in the Markov Model
   type Node is record
      Next_State : Bit_Array := (others => 0);
      Counts     : Count_Array := (others => 1);
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type => Node_Index, Element_Type => Node);

   -- Variants: Standard DMC starts single state, some implementations use Order-0 (255 nodes)
   type Initialization_Variant is (Single_State, Order_Zero);

   -- The Dynamic Markov Model
   type DMC_Model is tagged record
      Nodes          : Node_Vectors.Vector;
      Current        : State_ID := 0;
      Min_Cnt        : Natural := 2;
      Max_Cnt        : Natural := 2;
      Max_Memory     : State_ID := 100_000;
   end record;

   -- Subprograms
   procedure Initialize
     (Model      : in out DMC_Model;
      Init_Type  : Initialization_Variant := Single_State;
      Min_Cnt    : Natural := 2;
      Max_Cnt    : Natural := 2;
      Max_Memory : State_ID := 100_000);

   -- Predictive functions for Arithmetic Coding backend
   function Predict_Zero (Model : DMC_Model) return Float;
   function Predict_One (Model : DMC_Model) return Float;

   -- Feeds a bit into the model, triggering state cloning if thresholds are met
   procedure Update (Model : in out DMC_Model; B : Bit);

   -- Helper and state management functions
   function Get_State_Count (Model : DMC_Model) return Natural;
   function Current_State (Model : DMC_Model) return State_ID;
   procedure Reset_To_Start (Model : in out DMC_Model);

end Dynamic_Markov_Compression;
