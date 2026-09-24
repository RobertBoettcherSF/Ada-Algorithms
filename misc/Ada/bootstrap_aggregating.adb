with Ada.Numerics.Float_Random;
with Ada.Unchecked_Deallocation;

package body Bootstrap_Aggregating is

   -- Internal random number generator state for bootstrap sampling
   Gen : Ada.Numerics.Float_Random.Generator;

   -------------------------------------------------------------------------
   -- Bootstrap Sampling Helper
   -------------------------------------------------------------------------
   function Generate_Bootstrap_Sample
     (Source_Size : Natural;
      Target_Size : Natural) return Index_Array
   is
      Result : Index_Array (1 .. Target_Size);
      R      : Float;
      Val    : Float;
   begin
      if Source_Size = 0 or Target_Size = 0 then
         raise Invalid_Configuration_Error;
      end if;

      for I in Result'Range loop
         -- Draw a random float in [0.0, 1.0)
         R := Ada.Numerics.Float_Random.Random (Gen);
         
         -- Map to range 1.0 .. Float(Source_Size)
         Val := Float'Floor (R * Float (Source_Size)) + 1.0;
         
         -- Strict bound enforcement for edge cases
         if Val > Float (Source_Size) then
            Val := Float (Source_Size);
         elsif Val < 1.0 then
            Val := 1.0;
         end if;
         
         Result (I) := Dataset_Index (Val);
      end loop;
      
      return Result;
   end Generate_Bootstrap_Sample;

   -------------------------------------------------------------------------
   -- Classification Bagging
   -------------------------------------------------------------------------
   function Train_Classifier
     (Original_Size : Natural;
      Num_Models    : Positive;
      Trainer       : Classification_Trainer;
      Sample_Size   : Natural := 0) return Classification_Ensemble
   is
      Actual_Size : Natural := Sample_Size;
   begin
      -- Dynamic validations (in addition to Pre conditions)
      if Original_Size = 0 or Trainer = null then
         raise Invalid_Configuration_Error;
      end if;

      -- Standard bagging uses a sample size equal to the original dataset size
      if Actual_Size = 0 then
         Actual_Size := Original_Size;
      end if;

      declare
         -- Allocate unconstrained array on the stack
         Result : Classification_Ensemble (1 .. Num_Models);
      begin
         for I in Result'Range loop
            Result (I) := Trainer (Generate_Bootstrap_Sample (Original_Size, Actual_Size));
         end loop;
         return Result;
      end;
   end Train_Classifier;

   function Predict_Classifier
     (Ensemble : Classification_Ensemble;
      Item     : Dataset_Index) return Class_Label
   is
      Predictions   : Class_Array (Ensemble'Range);
      Max_Count     : Natural := 0;
      Current_Count : Natural;
      Mode          : Class_Label;
   begin
      if Ensemble'Length = 0 then
         raise Empty_Ensemble_Error;
      end if;

      -- 1. Gather all predictions
      for I in Ensemble'Range loop
         if Ensemble (I) = null then
            raise Invalid_Configuration_Error;
         end if;
         Predictions (I) := Ensemble (I).Predict (Item);
      end loop;

      -- 2. Find Mode (Majority Voting)
      Mode := Predictions (Predictions'First);
      for I in Predictions'Range loop
         Current_Count := 0;
         for J in Predictions'Range loop
            if Predictions (I) = Predictions (J) then
               Current_Count := Current_Count + 1;
            end if;
         end loop;

         -- Strict > ensures deterministic tie-breaking favoring the earliest encountered class
         if Current_Count > Max_Count then
            Max_Count := Current_Count;
            Mode := Predictions (I);
         end if;
      end loop;

      return Mode;
   end Predict_Classifier;

   procedure Free_Classifier_Ensemble (Ensemble : in out Classification_Ensemble) is
      procedure Free is new Ada.Unchecked_Deallocation
        (Object => Classification_Model'Class, Name => Classification_Model_Access);
   begin
      for I in Ensemble'Range loop
         if Ensemble (I) /= null then
            Free (Ensemble (I));
         end if;
      end loop;
   end Free_Classifier_Ensemble;


   -------------------------------------------------------------------------
   -- Regression Bagging
   -------------------------------------------------------------------------
   function Train_Regressor
     (Original_Size : Natural;
      Num_Models    : Positive;
      Trainer       : Regression_Trainer;
      Sample_Size   : Natural := 0) return Regression_Ensemble
   is
      Actual_Size : Natural := Sample_Size;
   begin
      -- Dynamic validations (in addition to Pre conditions)
      if Original_Size = 0 or Trainer = null then
         raise Invalid_Configuration_Error;
      end if;

      -- Standard bagging uses a sample size equal to the original dataset size
      if Actual_Size = 0 then
         Actual_Size := Original_Size;
      end if;

      declare
         Result : Regression_Ensemble (1 .. Num_Models);
      begin
         for I in Result'Range loop
            Result (I) := Trainer (Generate_Bootstrap_Sample (Original_Size, Actual_Size));
         end loop;
         return Result;
      end;
   end Train_Regressor;

   function Predict_Regressor
     (Ensemble : Regression_Ensemble;
      Item     : Dataset_Index) return Regression_Value
   is
      Sum : Regression_Value := 0.0;
   begin
      if Ensemble'Length = 0 then
         raise Empty_Ensemble_Error;
      end if;

      -- 1. Gather predictions and sum
      for I in Ensemble'Range loop
         if Ensemble (I) = null then
            raise Invalid_Configuration_Error;
         end if;
         Sum := Sum + Ensemble (I).Predict (Item);
      end loop;

      -- 2. Average the results
      return Sum / Regression_Value (Ensemble'Length);
   end Predict_Regressor;

   procedure Free_Regressor_Ensemble (Ensemble : in out Regression_Ensemble) is
      procedure Free is new Ada.Unchecked_Deallocation
        (Object => Regression_Model'Class, Name => Regression_Model_Access);
   begin
      for I in Ensemble'Range loop
         if Ensemble (I) /= null then
            Free (Ensemble (I));
         end if;
      end loop;
   end Free_Regressor_Ensemble;

-- Package Initialization: Seed the random number generator
begin
   Ada.Numerics.Float_Random.Reset (Gen);
end Bootstrap_Aggregating;
