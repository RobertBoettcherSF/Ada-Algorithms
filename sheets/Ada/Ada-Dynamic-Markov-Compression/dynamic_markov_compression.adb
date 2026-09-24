package body Dynamic_Markov_Compression is

   procedure Initialize
     (Model      : in out DMC_Model;
      Init_Type  : Initialization_Variant := Single_State;
      Min_Cnt    : Natural := 2;
      Max_Cnt    : Natural := 2;
      Max_Memory : State_ID := 100_000)
   is
   begin
      Model.Nodes.Clear;
      Model.Current := 0;
      Model.Min_Cnt := Min_Cnt;
      Model.Max_Cnt := Max_Cnt;
      Model.Max_Memory := Max_Memory;

      case Init_Type is
         when Single_State =>
            -- 1-node model looping to itself
            declare
               N : Node;
            begin
               N.Next_State := (0, 0);
               Model.Nodes.Append (N);
            end;
         when Order_Zero =>
            -- 8-bit context binary tree (255 nodes)
            for I in 0 .. 254 loop
               declare
                  N : Node;
               begin
                  if I < 127 then
                     N.Next_State (0) := State_ID (2 * I + 1);
                     N.Next_State (1) := State_ID (2 * I + 2);
                  else
                     N.Next_State := (0, 0); -- Loop back to root
                  end if;
                  Model.Nodes.Append (N);
               end;
            end loop;
      end case;
   end Initialize;

   function Predict_Zero (Model : DMC_Model) return Float is
      C_Node : constant Node := Model.Nodes.Element (Model.Current);
      Total  : constant Natural := C_Node.Counts (0) + C_Node.Counts (1);
   begin
      return Float (C_Node.Counts (0)) / Float (Total);
   end Predict_Zero;

   function Predict_One (Model : DMC_Model) return Float is
   begin
      return 1.0 - Predict_Zero (Model);
   end Predict_One;

   procedure Update (Model : in out DMC_Model; B : Bit) is
      C : constant State_ID := Model.Current;
      Node_C : Node := Model.Nodes.Element (C);
      
      N : constant State_ID := Node_C.Next_State (B);
      Node_N : Node := Model.Nodes.Element (N);

      C_To_N_Count : constant Natural := Node_C.Counts (B);
      N_Visits     : constant Natural := Node_N.Counts (0) + Node_N.Counts (1);
      
      -- Visits to N from states other than C
      Other_Visits : constant Integer := Integer'Max (0, N_Visits - C_To_N_Count);
   begin
      -- 1. Variant Support: Memory Bounded State Cloning
      if State_ID (Model.Nodes.Length) < Model.Max_Memory then
         -- Check DMC cloning threshold conditions
         if Other_Visits > Model.Min_Cnt and then C_To_N_Count > Model.Max_Cnt then
            declare
               N_Prime : Node;
               Ratio   : constant Float := Float (C_To_N_Count) / Float (N_Visits);
               C0      : constant Integer := Integer (Float (Node_N.Counts (0)) * Ratio);
               C1      : constant Integer := Integer (Float (Node_N.Counts (1)) * Ratio);
               N_Prime_ID : State_ID;
            begin
               -- Distribute counts proportionally, guaranteeing min count of 1
               N_Prime.Counts (0) := Integer'Max (1, C0);
               N_Prime.Counts (1) := Integer'Max (1, C1);
               N_Prime.Next_State := Node_N.Next_State;

               -- Deduct from original node
               Node_N.Counts (0) := Integer'Max (1, Node_N.Counts (0) - N_Prime.Counts (0));
               Node_N.Counts (1) := Integer'Max (1, Node_N.Counts (1) - N_Prime.Counts (1));

               -- Add N' to Markov Graph
               Model.Nodes.Append (N_Prime);
               N_Prime_ID := State_ID (Model.Nodes.Last_Index);

               -- Update pointers
               Node_C.Next_State (B) := N_Prime_ID;
               Model.Nodes.Replace_Element (N, Node_N);
            end;
         end if;
      end if;

      -- 2. Edge Case Handling: Prevent Integer Overflow on prolonged patterns
      if Node_C.Counts (B) > Natural'Last / 2 then
         Node_C.Counts (0) := Integer'Max (1, Node_C.Counts (0) / 2);
         Node_C.Counts (1) := Integer'Max (1, Node_C.Counts (1) / 2);
      end if;

      -- 3. Standard Markov Transition
      Node_C.Counts (B) := Node_C.Counts (B) + 1;
      Model.Nodes.Replace_Element (C, Node_C);
      Model.Current := Node_C.Next_State (B);
   end Update;

   function Get_State_Count (Model : DMC_Model) return Natural is
   begin
      return Natural (Model.Nodes.Length);
   end Get_State_Count;

   function Current_State (Model : DMC_Model) return State_ID is
   begin
      return Model.Current;
   end Current_State;

   procedure Reset_To_Start (Model : in out DMC_Model) is
   begin
      Model.Current := 0;
   end Reset_To_Start;

end Dynamic_Markov_Compression;
