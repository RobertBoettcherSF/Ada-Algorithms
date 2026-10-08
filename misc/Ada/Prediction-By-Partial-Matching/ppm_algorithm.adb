package body PPM_Algorithm is

   function To_Symbol_String (S : String) return Symbol_String is
      Res : Symbol_String (1 .. S'Length);
   begin
      for I in S'Range loop
         if Character'Pos(S(I)) <= 127 then
            Res(I - S'First + 1) := Symbol(S(I));
         else
            Res(I - S'First + 1) := Symbol('?'); -- Fallback for unsupported chars
         end if;
      end loop;
      return Res;
   end To_Symbol_String;

   procedure Update_Model (Model : in out Context_Model; S : Symbol) is
   begin
      if Model.Counts(S) = 0 then
         Model.Unique_Symbols := Model.Unique_Symbols + 1;
      end if;
      Model.Counts(S) := Model.Counts(S) + 1;
      Model.Total_Count := Model.Total_Count + 1;
   end Update_Model;

   procedure Estimate_Laplace (Model : in Context_Model; Result : out Model_Result) is
      Total : Float := Float (Model.Total_Count + 1);
   begin
      if Model.Total_Count = 0 then
         Result.Escape_Prob := 1.0;
         Result.Probs := (others => 0.0);
         return;
      end if;
      Result.Escape_Prob := Probability (1.0 / Total);
      for S in Symbol loop
         Result.Probs(S) := Probability (Float (Model.Counts(S)) / Total);
      end loop;
   end Estimate_Laplace;

   procedure Estimate_PPMd (Model : in Context_Model; Result : out Model_Result) is
      n : Float := Float(Model.Total_Count);
      q : Float := Float(Model.Unique_Symbols);
   begin
      if Model.Total_Count = 0 then
         Result.Escape_Prob := 1.0;
         Result.Probs := (others => 0.0);
         return;
      end if;
      Result.Escape_Prob := Probability (q / (2.0 * n));
      for S in Symbol loop
         if Model.Counts(S) > 0 then
            Result.Probs(S) := Probability ( (2.0 * Float(Model.Counts(S)) - 1.0) / (2.0 * n) );
         else
            Result.Probs(S) := 0.0;
         end if;
      end loop;
   end Estimate_PPMd;

   procedure Estimate_PPM_B (Model : in Context_Model; Result : out Model_Result) is
      n : Float := Float(Model.Total_Count);
      q : Float := Float(Model.Unique_Symbols);
   begin
      if Model.Total_Count = 0 then
         Result.Escape_Prob := 1.0;
         Result.Probs := (others => 0.0);
         return;
      end if;
      Result.Escape_Prob := Probability (q / n);
      for S in Symbol loop
         if Model.Counts(S) > 0 then
            Result.Probs(S) := Probability (Float(Model.Counts(S) - 1) / n);
         else
            Result.Probs(S) := 0.0;
         end if;
      end loop;
   end Estimate_PPM_B;

   procedure Estimate_PPM_C (Model : in Context_Model; Result : out Model_Result) is
      n : Float := Float(Model.Total_Count);
      q : Float := Float(Model.Unique_Symbols);
      Total : Float := n + q;
   begin
      if Model.Total_Count = 0 then
         Result.Escape_Prob := 1.0;
         Result.Probs := (others => 0.0);
         return;
      end if;
      Result.Escape_Prob := Probability (q / Total);
      for S in Symbol loop
         Result.Probs(S) := Probability (Float(Model.Counts(S)) / Total);
      end loop;
   end Estimate_PPM_C;

   procedure Initialize_Predictor
     (Predictor : out PPM_Predictor;
      Order     : Context_Order;
      Variant   : Estimation_Variant)
   is
   begin
      Predictor.Root := new Trie_Node;
      Predictor.Max_Order := Order;
      Predictor.Variant := Variant;
   end Initialize_Predictor;

   procedure Update_Predictor
     (Predictor : in out PPM_Predictor;
      History   : in Symbol_String;
      Next_Sym  : in Symbol)
   is
      Current : Trie_Access := Predictor.Root;
      Max_Len : Natural := History'Length;
   begin
      if Predictor.Max_Order /= Order_Unbounded and then Max_Len > Integer(Predictor.Max_Order) then
         Max_Len := Integer(Predictor.Max_Order);
      end if;

      -- Update base (order 0) context
      Update_Model (Current.Model, Next_Sym);

      -- Update dynamically deeper suffix contexts
      for I in 1 .. Max_Len loop
         declare
            C : Symbol := History (History'Last - I + 1);
         begin
            if Current.Children(C) = null then
               Current.Children(C) := new Trie_Node;
            end if;
            Current := Current.Children(C);
            Update_Model (Current.Model, Next_Sym);
         end;
      end loop;
   end Update_Predictor;

   function Calculate_Blended_Distribution
     (Predictor : PPM_Predictor;
      History   : Symbol_String) return Distribution
   is
      type Node_Array is array (0 .. 10_000) of Trie_Access;
      Nodes : Node_Array := (others => null);
      Count : Natural := 0;
      Current : Trie_Access := Predictor.Root;
      Max_Len : Natural := History'Length;

      Num_Syms : constant Float := Float (Character'Pos(Character'Val(127)) - Character'Pos(Character'Val(0)) + 1);
      Base_Prob : Probability := Probability (1.0 / Num_Syms);
      Result : Distribution := (others => Base_Prob);
   begin
      if Predictor.Max_Order /= Order_Unbounded and then Max_Len > Integer(Predictor.Max_Order) then
         Max_Len := Integer(Predictor.Max_Order);
      end if;

      Nodes (0) := Current;
      Count := 1;

      -- Walk up the suffix tree to find applicable contexts
      for I in 1 .. Max_Len loop
         declare
            C : Symbol := History (History'Last - I + 1);
         begin
            Current := Current.Children(C);
            if Current = null then
               exit;
            end if;
            Nodes (Count) := Current;
            Count := Count + 1;
         end;
      end loop;

      -- Resolve probabilities starting from lowest order blending upwards
      for I in 0 .. Count - 1 loop
         declare
            Node : Trie_Access := Nodes(I);
            MR   : Model_Result;
         begin
            if Node.Model.Total_Count > 0 then
               case Predictor.Variant is
                  when Laplace_Estimator => Estimate_Laplace(Node.Model, MR);
                  when PPMd_Estimator    => Estimate_PPMd(Node.Model, MR);
                  when PPM_B_Estimator   => Estimate_PPM_B(Node.Model, MR);
                  when PPM_C_Estimator   => Estimate_PPM_C(Node.Model, MR);
               end case;

               for S in Symbol loop
                  Result(S) := MR.Probs(S) + MR.Escape_Prob * Result(S);
               end loop;
            end if;
         end;
      end loop;

      return Result;
   end Calculate_Blended_Distribution;

   procedure Free_Predictor (Predictor : in out PPM_Predictor) is
      procedure Free_Node is new Ada.Unchecked_Deallocation (Trie_Node, Trie_Access);

      procedure Recursive_Free (Node : in out Trie_Access) is
      begin
         if Node /= null then
            for S in Symbol loop
               Recursive_Free (Node.Children(S));
            end loop;
            Free_Node (Node);
         end if;
      end Recursive_Free;
   begin
      Recursive_Free (Predictor.Root);
      Predictor.Root := null;
   end Free_Predictor;

end PPM_Algorithm;
