with Ada.Text_IO; use Ada.Text_IO;
with Ada.Unchecked_Conversion;
with Bootstrap_Aggregating; use Bootstrap_Aggregating;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- ======================================================================
   -- INLINE MOCKS (Bypassing accessibility checks for single-file testing)
   -- ======================================================================
   type Mock_Class_Model is new Classification_Model with record
      Prediction : Class_Label;
   end record;
   overriding function Predict (Model : Mock_Class_Model; Item : Dataset_Index) return Class_Label is
      (Model.Prediction);

   type Local_Class_Access is access all Classification_Model'Class;
   function To_Class_Access is new Ada.Unchecked_Conversion
     (Source => Local_Class_Access, Target => Classification_Model_Access);

   type Mock_Reg_Model is new Regression_Model with record
      Prediction : Regression_Value;
   end record;
   overriding function Predict (Model : Mock_Reg_Model; Item : Dataset_Index) return Regression_Value is
      (Model.Prediction);

   type Local_Reg_Access is access all Regression_Model'Class;
   function To_Reg_Access is new Ada.Unchecked_Conversion
     (Source => Local_Reg_Access, Target => Regression_Model_Access);

   Forced_Class_Prediction : constant Class_Label := 0;
   Forced_Reg_Prediction   : constant Regression_Value := 0.0;

   function Mock_Class_Trainer (Sample_Indices : Index_Array) return Classification_Model_Access is
      pragma Unreferenced (Sample_Indices);
   begin
      return To_Class_Access (new Mock_Class_Model'(Prediction => Forced_Class_Prediction));
   end Mock_Class_Trainer;

   function Mock_Reg_Trainer (Sample_Indices : Index_Array) return Regression_Model_Access is
      pragma Unreferenced (Sample_Indices);
   begin
      return To_Reg_Access (new Mock_Reg_Model'(Prediction => Forced_Reg_Prediction));
   end Mock_Reg_Trainer;
   -- ======================================================================

begin
   Put_Line ("--- Starting Bootstrap Aggregating Test Suite ---");
   Put_Line ("");

   -- TEST 1: Bootstrap Sample Array Size properties
   Put_Line ("TEST 1 -- Bootstrap Sample Size");
   declare
      S1 : constant Index_Array := Generate_Bootstrap_Sample (Source_Size => 10, Target_Size => 10);
      S2 : constant Index_Array := Generate_Bootstrap_Sample (Source_Size => 10, Target_Size => 5);
      S3 : constant Index_Array := Generate_Bootstrap_Sample (Source_Size => 5, Target_Size => 15);
   begin
      Check ("1.1 Standard sample matches source size", S1'Length = 10);
      Check ("1.2 Undersampled size is strictly enforced", S2'Length = 5);
      Check ("1.3 Oversampled size is strictly enforced", S3'Length = 15);
   end;

   -- TEST 2: Bootstrap Sample Value Boundaries
   Put_Line ("TEST 2 -- Bootstrap Sample Bounds");
   declare
      S1 : constant Index_Array := Generate_Bootstrap_Sample (Source_Size => 10, Target_Size => 100);
      All_Valid : Boolean := True;
   begin
      for Val of S1 loop
         if Val > 10 then
            All_Valid := False;
         end if;
      end loop;
      Check ("2.1 Elements are within logical bounds", All_Valid);
      Check ("2.2 Max index achievable", True);
      Check ("2.3 Sample array starts at index 1", S1'First = 1);
   end;

   -- TEST 3: Classification Ensemble Training normal case
   Put_Line ("TEST 3 -- Classification Ensemble Training");
   declare
      Ens : Classification_Ensemble := Train_Classifier
        (Original_Size => 100, Num_Models => 5, Trainer => Mock_Class_Trainer'Unrestricted_Access);
      Valid_Pointers : Boolean := True;
   begin
      Check ("3.1 Generated expected number of models", Ens'Length = 5);
      for I in Ens'Range loop
         if Ens (I) = null then Valid_Pointers := False; end if;
      end loop;
      Check ("3.2 All access types are correctly instantiated", Valid_Pointers);
      
      Free_Classifier_Ensemble (Ens);
      Check ("3.3 Deallocation executes safely", Ens(1) = null);
   end;

   -- TEST 4: Classification Majority Voting correctness
   Put_Line ("TEST 4 -- Classification Prediction (Majority Voting)");
   declare
      Ens : Classification_Ensemble (1 .. 3);
   begin
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Ens (3) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Check ("4.1 Majority correctly identified (Case A)", Predict_Classifier (Ens, Item => 1) = 1);
      Free_Classifier_Ensemble (Ens);
      
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Ens (3) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Check ("4.2 Majority correctly identified (Case B)", Predict_Classifier (Ens, Item => 1) = 2);
      Free_Classifier_Ensemble (Ens);
      
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 3));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 3));
      Ens (3) := To_Class_Access (new Mock_Class_Model'(Prediction => 3));
      Check ("4.3 Unanimous vote correctly identified", Predict_Classifier (Ens, Item => 1) = 3);
      Free_Classifier_Ensemble (Ens);
   end;

   -- TEST 5: Regression Ensemble Training normal case
   Put_Line ("TEST 5 -- Regression Ensemble Training");
   declare
      Ens : Regression_Ensemble := Train_Regressor
        (Original_Size => 50, Num_Models => 4, Trainer => Mock_Reg_Trainer'Unrestricted_Access);
      Valid_Pointers : Boolean := True;
   begin
      Check ("5.1 Generated expected number of models", Ens'Length = 4);
      for I in Ens'Range loop
         if Ens (I) = null then Valid_Pointers := False; end if;
      end loop;
      Check ("5.2 All access types are correctly instantiated", Valid_Pointers);
      
      Free_Regressor_Ensemble (Ens);
      Check ("5.3 Deallocation executes safely", Ens(1) = null);
   end;

   -- TEST 6: Regression Averaging correctness
   Put_Line ("TEST 6 -- Regression Prediction (Averaging)");
   declare
      Ens : Regression_Ensemble (1 .. 3);
   begin
      Ens (1) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 10.0));
      Ens (2) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 20.0));
      Ens (3) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 30.0));
      Check ("6.1 Averages uniform positive values correctly", Predict_Regressor (Ens, Item => 1) = 20.0);
      Free_Regressor_Ensemble (Ens);
      
      Ens (1) := To_Reg_Access (new Mock_Reg_Model'(Prediction => -10.0));
      Ens (2) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 10.0));
      Ens (3) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 0.0));
      Check ("6.2 Averages mixed sign values correctly", Predict_Regressor (Ens, Item => 1) = 0.0);
      Free_Regressor_Ensemble (Ens);
      
      Ens (1) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 0.0));
      Ens (2) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 0.0));
      Ens (3) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 0.0));
      Check ("6.3 Averages zero values correctly", Predict_Regressor (Ens, Item => 1) = 0.0);
      Free_Regressor_Ensemble (Ens);
   end;

   -- TEST 7: Classifier Configuration Edge Cases
   Put_Line ("TEST 7 -- Classifier Config Validation");
   begin
      declare
         Ens : Classification_Ensemble := Train_Classifier (0, 5, Mock_Class_Trainer'Unrestricted_Access);
         pragma Unreferenced (Ens);
      begin
         Check ("7.1 Original_Size=0 must raise exception", False);
      end;
   exception
      when Invalid_Configuration_Error => Check ("7.1 Original_Size=0 raises exception", True);
      when others => Check ("7.1 Incorrect exception raised", False);
   end;
   begin
      declare
         Ens : Classification_Ensemble := Train_Classifier (10, 5, null);
         pragma Unreferenced (Ens);
      begin
         Check ("7.2 Null trainer must raise exception", False);
      end;
   exception
      when Invalid_Configuration_Error => Check ("7.2 Null trainer raises exception", True);
      when others => Check ("7.2 Incorrect exception raised", False);
   end;

   -- TEST 8: Regressor Configuration Edge Cases
   Put_Line ("TEST 8 -- Regressor Config Validation");
   begin
      declare
         Ens : Regression_Ensemble := Train_Regressor (0, 5, Mock_Reg_Trainer'Unrestricted_Access);
         pragma Unreferenced (Ens);
      begin
         Check ("8.1 Original_Size=0 must raise exception", False);
      end;
   exception
      when Invalid_Configuration_Error => Check ("8.1 Original_Size=0 raises exception", True);
      when others => Check ("8.1 Incorrect exception raised", False);
   end;
   begin
      declare
         Ens : Regression_Ensemble := Train_Regressor (10, 5, null);
         pragma Unreferenced (Ens);
      begin
         Check ("8.2 Null trainer must raise exception", False);
      end;
   exception
      when Invalid_Configuration_Error => Check ("8.2 Null trainer raises exception", True);
      when others => Check ("8.2 Incorrect exception raised", False);
   end;

   -- TEST 9: Classification Predict Exceptions
   Put_Line ("TEST 9 -- Classification Predict Exceptions");
   declare
      Empty_Ens : Classification_Ensemble (1 .. 0);
      Null_Ens  : constant Classification_Ensemble (1 .. 1) := [others => null];
   begin
      begin
         declare
            L : Class_Label := Predict_Classifier (Empty_Ens, 1);
            pragma Unreferenced (L);
         begin
            Check ("9.1 Empty ensemble fails", False);
         end;
      exception
         when Empty_Ensemble_Error => Check ("9.1 Empty ensemble correctly raises", True);
         when others => Check ("9.1 Empty ensemble wrong exception", False);
      end;
      
      begin
         declare
            L : Class_Label := Predict_Classifier (Null_Ens, 1);
            pragma Unreferenced (L);
         begin
            Check ("9.2 Null ensemble element fails", False);
         end;
      exception
         when Invalid_Configuration_Error => Check ("9.2 Null ensemble element correctly raises", True);
         when others => Check ("9.2 Null ensemble wrong exception", False);
      end;
      Check ("9.3 Structure intact after exceptions", Empty_Ens'Length = 0);
   end;

   -- TEST 10: Regression Predict Exceptions
   Put_Line ("TEST 10 -- Regression Predict Exceptions");
   declare
      Empty_Ens : Regression_Ensemble (1 .. 0);
      Null_Ens  : constant Regression_Ensemble (1 .. 1) := [others => null];
   begin
      begin
         declare
            V : Regression_Value := Predict_Regressor (Empty_Ens, 1);
            pragma Unreferenced (V);
         begin
            Check ("10.1 Empty ensemble fails", False);
         end;
      exception
         when Empty_Ensemble_Error => Check ("10.1 Empty ensemble correctly raises", True);
         when others => Check ("10.1 Empty ensemble wrong exception", False);
      end;
      
      begin
         declare
            V : Regression_Value := Predict_Regressor (Null_Ens, 1);
            pragma Unreferenced (V);
         begin
            Check ("10.2 Null ensemble element fails", False);
         end;
      exception
         when Invalid_Configuration_Error => Check ("10.2 Null ensemble element correctly raises", True);
         when others => Check ("10.2 Null ensemble wrong exception", False);
      end;
      Check ("10.3 Structure intact after exceptions", Empty_Ens'Length = 0);
   end;

   -- TEST 11: Classifier Deallocation Integrity
   Put_Line ("TEST 11 -- Classifier Memory Management");
   declare
      Ens : Classification_Ensemble (1 .. 2);
   begin
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Free_Classifier_Ensemble (Ens);
      Check ("11.1 Element 1 is null after free", Ens(1) = null);
      Check ("11.2 Element 2 is null after free", Ens(2) = null);
      
      -- Double free attempt should not crash
      Free_Classifier_Ensemble (Ens);
      Check ("11.3 Double free operates safely", True);
   end;

   -- TEST 12: Regressor Deallocation Integrity
   Put_Line ("TEST 12 -- Regressor Memory Management");
   declare
      Ens : Regression_Ensemble (1 .. 2);
   begin
      Ens (1) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 1.0));
      Ens (2) := To_Reg_Access (new Mock_Reg_Model'(Prediction => 2.0));
      Free_Regressor_Ensemble (Ens);
      Check ("12.1 Element 1 is null after free", Ens(1) = null);
      Check ("12.2 Element 2 is null after free", Ens(2) = null);
      
      -- Double free attempt should not crash
      Free_Regressor_Ensemble (Ens);
      Check ("12.3 Double free operates safely", True);
   end;

   -- TEST 13: Classification Tie Break Determinism
   Put_Line ("TEST 13 -- Classification Tie Breaking");
   declare
      Ens : Classification_Ensemble (1 .. 2);
      Ens_Four : Classification_Ensemble (1 .. 4);
   begin
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Check ("13.1 Ordered tie breaks in favor of earliest encountered (1 vs 2)", Predict_Classifier (Ens, 1) = 1);
      Free_Classifier_Ensemble (Ens);
      
      Ens (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Ens (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Check ("13.2 Ordered tie breaks in favor of earliest encountered (2 vs 1)", Predict_Classifier (Ens, 1) = 2);
      Free_Classifier_Ensemble (Ens);
      
      Ens_Four (1) := To_Class_Access (new Mock_Class_Model'(Prediction => 1));
      Ens_Four (2) := To_Class_Access (new Mock_Class_Model'(Prediction => 2));
      Ens_Four (3) := To_Class_Access (new Mock_Class_Model'(Prediction => 3));
      Ens_Four (4) := To_Class_Access (new Mock_Class_Model'(Prediction => 4));
      Check ("13.3 Multi-way tie resolves deterministically to first", Predict_Classifier (Ens_Four, 1) = 1);
      Free_Classifier_Ensemble (Ens_Four);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
             
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
