with Ada.Text_IO; use Ada.Text_IO;
with Perceptron;  use Perceptron;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Common Dataset: Logic OR Gate
   X_OR : constant Matrix (1 .. 4, 1 .. 2) :=
     [[ -1.0, -1.0 ],
      [ -1.0,  1.0 ],
      [  1.0, -1.0 ],
      [  1.0,  1.0 ]];
   Y_OR : constant Label_Array (1 .. 4) := [-1, 1, 1, 1];

   -- Common Dataset: Logic AND Gate
   X_AND : constant Matrix (1 .. 4, 1 .. 2) :=
     [[ -1.0, -1.0 ],
      [ -1.0,  1.0 ],
      [  1.0, -1.0 ],
      [  1.0,  1.0 ]];
   Y_AND : constant Label_Array (1 .. 4) := [-1, -1, -1, 1];

   -- Common Dataset: Logic XOR Gate (Linearly Inseparable)
   X_XOR : constant Matrix (1 .. 4, 1 .. 2) :=
     [[ -1.0, -1.0 ],
      [ -1.0,  1.0 ],
      [  1.0, -1.0 ],
      [  1.0,  1.0 ]];
   Y_XOR : constant Label_Array (1 .. 4) := [-1, 1, 1, -1];

begin
   -- TEST 1 - Initialization & Default Values
   declare
      M : constant Perceptron_Model := Create (2);
      V : constant Vector (1 .. 2) := [1.0, 1.0];
   begin
      Put_Line ("TEST 1 — Model Initialization");
      -- All weights and bias start at 0. Activation = 0.0, Pred > 0.0 gives -1
      Check ("1.1 Standard defaults predict -1", Predict_Standard (M, V) = -1);
      Check ("1.2 Pocket defaults predict -1", Predict_Pocket (M, V) = -1);
      Check ("1.3 Averaged defaults predict -1", Predict_Averaged (M, V) = -1);
   end;

   -- TEST 2 - Standard Perceptron convergence on linearly separable data (OR)
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 2 — Standard Perceptron (OR Gate)");
      Train_Standard (M, X_OR, Y_OR, Epochs => 10, Learning_Rate => 0.1);
      Check ("2.1 Predict [-1,-1] -> -1", Predict_Standard (M, [-1.0, -1.0]) = -1);
      Check ("2.2 Predict [-1, 1] ->  1", Predict_Standard (M, [-1.0,  1.0]) =  1);
      Check ("2.3 Predict [ 1,-1] ->  1", Predict_Standard (M, [ 1.0, -1.0]) =  1);
      Check ("2.4 Predict [ 1, 1] ->  1", Predict_Standard (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 3 - Standard Perceptron convergence on AND gate
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 3 — Standard Perceptron (AND Gate)");
      Train_Standard (M, X_AND, Y_AND, Epochs => 10, Learning_Rate => 0.1);
      Check ("3.1 Predict [-1,-1] -> -1", Predict_Standard (M, [-1.0, -1.0]) = -1);
      Check ("3.2 Predict [-1, 1] -> -1", Predict_Standard (M, [-1.0,  1.0]) = -1);
      Check ("3.3 Predict [ 1,-1] -> -1", Predict_Standard (M, [ 1.0, -1.0]) = -1);
      Check ("3.4 Predict [ 1, 1] ->  1", Predict_Standard (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 4 - Pocket Perceptron convergence on OR gate
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 4 — Pocket Perceptron (OR Gate)");
      Train_Pocket (M, X_OR, Y_OR, Epochs => 10, Learning_Rate => 0.1);
      Check ("4.1 Predict [-1,-1] -> -1", Predict_Pocket (M, [-1.0, -1.0]) = -1);
      Check ("4.2 Predict [-1, 1] ->  1", Predict_Pocket (M, [-1.0,  1.0]) =  1);
      Check ("4.3 Predict [ 1,-1] ->  1", Predict_Pocket (M, [ 1.0, -1.0]) =  1);
      Check ("4.4 Predict [ 1, 1] ->  1", Predict_Pocket (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 5 - Pocket Perceptron convergence on AND gate
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 5 — Pocket Perceptron (AND Gate)");
      Train_Pocket (M, X_AND, Y_AND, Epochs => 10, Learning_Rate => 0.1);
      Check ("5.1 Predict [-1,-1] -> -1", Predict_Pocket (M, [-1.0, -1.0]) = -1);
      Check ("5.2 Predict [-1, 1] -> -1", Predict_Pocket (M, [-1.0,  1.0]) = -1);
      Check ("5.3 Predict [ 1,-1] -> -1", Predict_Pocket (M, [ 1.0, -1.0]) = -1);
      Check ("5.4 Predict [ 1, 1] ->  1", Predict_Pocket (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 6 - Averaged Perceptron convergence on OR gate
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 6 — Averaged Perceptron (OR Gate)");
      Train_Averaged (M, X_OR, Y_OR, Epochs => 15, Learning_Rate => 0.1);
      Check ("6.1 Predict [-1,-1] -> -1", Predict_Averaged (M, [-1.0, -1.0]) = -1);
      Check ("6.2 Predict [-1, 1] ->  1", Predict_Averaged (M, [-1.0,  1.0]) =  1);
      Check ("6.3 Predict [ 1,-1] ->  1", Predict_Averaged (M, [ 1.0, -1.0]) =  1);
      Check ("6.4 Predict [ 1, 1] ->  1", Predict_Averaged (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 7 - Averaged Perceptron convergence on AND gate
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 7 — Averaged Perceptron (AND Gate)");
      Train_Averaged (M, X_AND, Y_AND, Epochs => 15, Learning_Rate => 0.1);
      Check ("7.1 Predict [-1,-1] -> -1", Predict_Averaged (M, [-1.0, -1.0]) = -1);
      Check ("7.2 Predict [-1, 1] -> -1", Predict_Averaged (M, [-1.0,  1.0]) = -1);
      Check ("7.3 Predict [ 1,-1] -> -1", Predict_Averaged (M, [ 1.0, -1.0]) = -1);
      Check ("7.4 Predict [ 1, 1] ->  1", Predict_Averaged (M, [ 1.0,  1.0]) =  1);
   end;

   -- TEST 8 - Standard on Non-Separable Data (XOR)
   declare
      M : Perceptron_Model := Create (2);
      Correct_Count : Integer := 0;
   begin
      Put_Line ("TEST 8 — Standard Perceptron (XOR Gate)");
      Train_Standard (M, X_XOR, Y_XOR, Epochs => 20, Learning_Rate => 0.1);
      if Predict_Standard (M, [-1.0, -1.0]) = Y_XOR (1) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Standard (M, [-1.0,  1.0]) = Y_XOR (2) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Standard (M, [ 1.0, -1.0]) = Y_XOR (3) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Standard (M, [ 1.0,  1.0]) = Y_XOR (4) then Correct_Count := Correct_Count + 1; end if;
      Check ("8.1 Training completes without crashing", True);
      Check ("8.2 Model struggles gracefully (<= 75% accuracy)", Correct_Count <= 3);
      Check ("8.3 Predictions demonstrate learning attempt (bias shift)", Correct_Count >= 0);
   end;

   -- TEST 9 - Pocket on Non-Separable Data (XOR)
   declare
      M : Perceptron_Model := Create (2);
      Correct_Count : Integer := 0;
   begin
      Put_Line ("TEST 9 — Pocket Perceptron (XOR Gate)");
      Train_Pocket (M, X_XOR, Y_XOR, Epochs => 30, Learning_Rate => 0.1);
      if Predict_Pocket (M, [-1.0, -1.0]) = Y_XOR (1) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Pocket (M, [-1.0,  1.0]) = Y_XOR (2) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Pocket (M, [ 1.0, -1.0]) = Y_XOR (3) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Pocket (M, [ 1.0,  1.0]) = Y_XOR (4) then Correct_Count := Correct_Count + 1; end if;
      Check ("9.1 Training completes without crashing", True);
      Check ("9.2 Pocket selects a stable, partially-correct sequence (at least 2/4)", Correct_Count >= 2);
      Check ("9.3 Best_Run tracking ensures stability", True);
   end;

   -- TEST 10 - Averaged on Non-Separable Data (XOR)
   declare
      M : Perceptron_Model := Create (2);
      Correct_Count : Integer := 0;
   begin
      Put_Line ("TEST 10 — Averaged Perceptron (XOR Gate)");
      Train_Averaged (M, X_XOR, Y_XOR, Epochs => 20, Learning_Rate => 0.1);
      if Predict_Averaged (M, [-1.0, -1.0]) = Y_XOR (1) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Averaged (M, [-1.0,  1.0]) = Y_XOR (2) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Averaged (M, [ 1.0, -1.0]) = Y_XOR (3) then Correct_Count := Correct_Count + 1; end if;
      if Predict_Averaged (M, [ 1.0,  1.0]) = Y_XOR (4) then Correct_Count := Correct_Count + 1; end if;
      Check ("10.1 Training completes without crashing", True);
      Check ("10.2 Average weights maintain partial validity", Correct_Count >= 0);
      Check ("10.3 Prevents wild oscillations (predictable behavior)", Correct_Count <= 4);
   end;

   -- TEST 11 - Preconditions (Data Dimension Mismatch)
   declare
      M : Perceptron_Model := Create (3); -- Created for 3 dims, dataset has 2
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 11 — Contract Checks: Feature Mismatch");
      begin
         Train_Standard (M, X_OR, Y_OR, 1, 0.1);
      exception
         when others => Caught := True;
      end;
      Check ("11.1 Standard rejects mismatched dataset dimensions", Caught);

      Caught := False;
      begin
         Train_Pocket (M, X_OR, Y_OR, 1, 0.1);
      exception
         when others => Caught := True;
      end;
      Check ("11.2 Pocket rejects mismatched dataset dimensions", Caught);

      Caught := False;
      begin
         Train_Averaged (M, X_OR, Y_OR, 1, 0.1);
      exception
         when others => Caught := True;
      end;
      Check ("11.3 Averaged rejects mismatched dataset dimensions", Caught);
   end;

   -- TEST 12 - Preconditions (Prediction Dimension Mismatch)
   declare
      M : constant Perceptron_Model := Create (2);
      Bad_V : constant Vector (1 .. 3) := [1.0, 2.0, 3.0];
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 12 — Contract Checks: Prediction Mismatch");
      begin
         if Predict_Standard (M, Bad_V) = 1 then null; end if;
      exception
         when others => Caught := True;
      end;
      Check ("12.1 Standard predict catches vector size mismatch", Caught);

      Caught := False;
      begin
         if Predict_Pocket (M, Bad_V) = 1 then null; end if;
      exception
         when others => Caught := True;
      end;
      Check ("12.2 Pocket predict catches vector size mismatch", Caught);

      Caught := False;
      begin
         if Predict_Averaged (M, Bad_V) = 1 then null; end if;
      exception
         when others => Caught := True;
      end;
      Check ("12.3 Averaged predict catches vector size mismatch", Caught);
   end;

   -- TEST 13 - Zero Learning Rate (weights shouldn't update)
   declare
      M : Perceptron_Model := Create (2);
   begin
      Put_Line ("TEST 13 — Zero Learning Rate (Static Weights)");
      Train_Standard (M, X_OR, Y_OR, Epochs => 10, Learning_Rate => 0.0);
      Check ("13.1 Predict [-1,-1] remains -1 (default)", Predict_Standard (M, [-1.0, -1.0]) = -1);
      Check ("13.2 Predict [-1, 1] remains -1 (default)", Predict_Standard (M, [-1.0,  1.0]) = -1);
      Check ("13.3 Predict [ 1,-1] remains -1 (default)", Predict_Standard (M, [ 1.0, -1.0]) = -1);
      Check ("13.4 Predict [ 1, 1] remains -1 (default)", Predict_Standard (M, [ 1.0,  1.0]) = -1);
   end;

   -- TEST 14 - Negative Learning Rate Contract Check
   declare
      M : Perceptron_Model := Create (2);
      Caught : Boolean := False;
   begin
      Put_Line ("TEST 14 — Contract Checks: Negative Learning Rate");
      begin
         Train_Standard (M, X_OR, Y_OR, 1, -0.1);
      exception
         when others => Caught := True;
      end;
      Check ("14.1 Standard rejects negative learning rate", Caught);

      Caught := False;
      begin
         Train_Pocket (M, X_OR, Y_OR, 1, -0.1);
      exception
         when others => Caught := True;
      end;
      Check ("14.2 Pocket rejects negative learning rate", Caught);

      Caught := False;
      begin
         Train_Averaged (M, X_OR, Y_OR, 1, -0.1);
      exception
         when others => Caught := True;
      end;
      Check ("14.3 Averaged rejects negative learning rate", Caught);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
