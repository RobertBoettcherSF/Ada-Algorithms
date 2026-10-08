package Knn is
   pragma Pure (Knn);

   type Feature_Value is new Long_Float;
   type Distance_Value is new Long_Float;
   type Sample_Index is new Positive;
   type Feature_Index is new Positive;
   type Class_Label is new Natural;
   type K_Value is new Positive;

   type Feature_Matrix is array (Sample_Index range <>, Feature_Index range <>) of Feature_Value;
   type Query_Vector is array (Feature_Index range <>) of Feature_Value;
   type Label_Vector is array (Sample_Index range <>) of Class_Label;
   type Target_Vector is array (Sample_Index range <>) of Feature_Value;

   -- Exceptions for robust error handling
   Empty_Dataset_Error      : exception;
   Invalid_K_Error          : exception;
   Dimension_Mismatch_Error : exception;
   Length_Mismatch_Error    : exception;

   -- 1. Basic K-Nearest Neighbors Classification (Majority Vote)
   function Predict_Classification
     (Train_X : Feature_Matrix;
      Train_Y : Label_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Class_Label
     with Pre => Train_X'Length(1) > 0
                 and then Train_X'Length(1) = Train_Y'Length
                 and then Train_X'Length(2) = Query'Length
                 and then Natural(K) <= Train_X'Length(1),
          Global => null;

   -- 2. Basic K-Nearest Neighbors Regression (Uniform Average)
   function Predict_Regression
     (Train_X : Feature_Matrix;
      Train_Y : Target_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Feature_Value
     with Pre => Train_X'Length(1) > 0
                 and then Train_X'Length(1) = Train_Y'Length
                 and then Train_X'Length(2) = Query'Length
                 and then Natural(K) <= Train_X'Length(1),
          Global => null;

   -- 3. Distance-Weighted K-Nearest Neighbors Classification
   function Predict_Weighted_Classification
     (Train_X : Feature_Matrix;
      Train_Y : Label_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Class_Label
     with Pre => Train_X'Length(1) > 0
                 and then Train_X'Length(1) = Train_Y'Length
                 and then Train_X'Length(2) = Query'Length
                 and then Natural(K) <= Train_X'Length(1),
          Global => null;

   -- 4. Distance-Weighted K-Nearest Neighbors Regression
   function Predict_Weighted_Regression
     (Train_X : Feature_Matrix;
      Train_Y : Target_Vector;
      Query   : Query_Vector;
      K       : K_Value) return Feature_Value
     with Pre => Train_X'Length(1) > 0
                 and then Train_X'Length(1) = Train_Y'Length
                 and then Train_X'Length(2) = Query'Length
                 and then Natural(K) <= Train_X'Length(1),
          Global => null;

end Knn;
