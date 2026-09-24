--  Chinese_Whispers body — weighted adjacency graphs, LCG shuffle,
--  plurality label updates, Biemann–Teresniak Chinese Whispers driver.

pragma Ada_2022;

package body Chinese_Whispers
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Find_Neighbor_Index
     (N : Node_Neighbors; Id : Node_Id) return Natural
   is
   begin
      for I in 1 .. N.Degree loop
         if N.Nodes (I) = Id then
            return I;
         end if;
      end loop;
      return 0;
   end Find_Neighbor_Index;

   procedure Append_Or_Add_Weight
     (N : in out Node_Neighbors; Id : Node_Id; W : Weight)
   is
      Idx : constant Natural := Find_Neighbor_Index (N, Id);
   begin
      if Idx > 0 then
         N.Weights (Idx) := N.Weights (Idx) + W;
         return;
      end if;
      if N.Degree = Max_Degree then
         raise Capacity_Exceeded with "neighbor list full";
      end if;
      N.Degree := N.Degree + 1;
      N.Nodes (N.Degree) := Id;
      N.Weights (N.Degree) := W;
   end Append_Or_Add_Weight;

   procedure Require_Labels_Aligned (G : Graph; Labels : Label_Array) is
   begin
      if Labels'First /= G'First or else Labels'Last /= G'Last then
         raise Invalid_Argument with "Labels range must match Graph";
      end if;
   end Require_Labels_Aligned;

   function Is_Permutation (G : Graph; Order : Node_Array) return Boolean is
      Seen : array (G'Range) of Boolean := [others => False];
   begin
      if Order'Length /= G'Length then
         return False;
      end if;
      if G'Length = 0 then
         return True;
      end if;
      for I in Order'Range loop
         if Order (I) not in G'Range then
            return False;
         end if;
         if Seen (Order (I)) then
            return False;
         end if;
         Seen (Order (I)) := True;
      end loop;
      for N in G'Range loop
         if not Seen (N) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Permutation;

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   function Empty_Graph (N : Node_Count) return Graph is
   begin
      if N = 0 then
         declare
            G : Graph (1 .. 0);
         begin
            return G;
         end;
      end if;
      declare
         G : Graph (1 .. Node_Id (N));
      begin
         for D in G'Range loop
            G (D).Degree := 0;
         end loop;
         return G;
      end;
   end Empty_Graph;

   procedure Add_Undirected_Edge
     (G : in out Graph;
      A, B : Node_Id;
      W : Weight := 1.0)
   is
   begin
      if A not in G'Range or else B not in G'Range then
         raise Invalid_Argument with "Add_Undirected_Edge: id out of range";
      end if;
      if A = B then
         raise Invalid_Argument with "Add_Undirected_Edge: self-loop";
      end if;
      Append_Or_Add_Weight (G (A), B, W);
      Append_Or_Add_Weight (G (B), A, W);
   end Add_Undirected_Edge;

   function Degree (G : Graph; N : Node_Id) return Natural is
   begin
      if N not in G'Range then
         raise Invalid_Argument with "Degree: node id out of range";
      end if;
      return Natural (G (N).Degree);
   end Degree;

   function Edge_Weight
     (G : Graph; A, B : Node_Id) return Weight
   is
      Idx : Natural;
   begin
      if A not in G'Range or else B not in G'Range then
         raise Invalid_Argument with "Edge_Weight: id out of range";
      end if;
      Idx := Find_Neighbor_Index (G (A), B);
      if Idx = 0 then
         return 0.0;
      end if;
      return G (A).Weights (Idx);
   end Edge_Weight;

   -------------------------------------------------------------------------
   -- Label / score helpers
   -------------------------------------------------------------------------

   function Init_Labels (G : Graph) return Label_Array is
   begin
      if G'Length = 0 then
         declare
            Empty : Label_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      declare
         L : Label_Array (G'Range);
      begin
         for N in G'Range loop
            L (N) := N;
         end loop;
         return L;
      end;
   end Init_Labels;

   function Neighbor_Label_Score
     (G      : Graph;
      Labels : Label_Array;
      N      : Node_Id;
      L      : Label_Id) return Weight
   is
      S : Weight := 0.0;
      Nb : Node_Id;
   begin
      if N not in G'Range then
         raise Invalid_Argument with "Neighbor_Label_Score: node out of range";
      end if;
      Require_Labels_Aligned (G, Labels);
      for I in 1 .. G (N).Degree loop
         Nb := G (N).Nodes (I);
         if Labels (Nb) = L then
            S := S + G (N).Weights (I);
         end if;
      end loop;
      return S;
   end Neighbor_Label_Score;

   function Cluster_Count (Labels : Label_Array) return Natural is
      Count : Natural := 0;
      Seen  : array (Node_Id) of Boolean := [others => False];
   begin
      for I in Labels'Range loop
         if not Seen (Labels (I)) then
            Seen (Labels (I)) := True;
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Cluster_Count;

   procedure Relabel_Contiguous (Labels : in out Label_Array) is
      Next_Id : Natural := 0;
      Map     : array (Node_Id) of Natural := [others => 0];
      Old     : Label_Id;
   begin
      if Labels'Length = 0 then
         return;
      end if;
      for I in Labels'Range loop
         Old := Labels (I);
         if Map (Old) = 0 then
            Next_Id := Next_Id + 1;
            Map (Old) := Next_Id;
         end if;
      end loop;
      for I in Labels'Range loop
         Labels (I) := Label_Id (Map (Labels (I)));
      end loop;
   end Relabel_Contiguous;

   -------------------------------------------------------------------------
   -- RNG / shuffle
   -------------------------------------------------------------------------

   function Init_RNG (Seed : Natural) return RNG_State is
      S : RNG_State;
      V : Natural := Seed mod LCG_Modulus;
   begin
      if V = 0 then
         V := 1;
      end if;
      S.Value := V;
      return S;
   end Init_RNG;

   function Next_Random (State : in out RNG_State) return Natural is
      Acc : constant Long_Long_Integer :=
        Long_Long_Integer (LCG_Multiplier) * Long_Long_Integer (State.Value);
      Next : constant Long_Long_Integer :=
        Acc rem Long_Long_Integer (LCG_Modulus);
   begin
      State.Value := Natural (Next);
      if State.Value = 0 then
         State.Value := 1;
      end if;
      return State.Value;
   end Next_Random;

   procedure Shuffle_Nodes
     (Order : in out Node_Array;
      State : in out RNG_State)
   is
      J   : Node_Id;
      Tmp : Node_Id;
      Span : Natural;
      R   : Natural;
   begin
      if Order'Length <= 1 then
         return;
      end if;
      for I in reverse Order'First + 1 .. Order'Last loop
         Span := Natural (I - Order'First) + 1;
         R := Next_Random (State) mod Span;
         J := Node_Id (Natural (Order'First) + R);
         Tmp := Order (I);
         Order (I) := Order (J);
         Order (J) := Tmp;
      end loop;
   end Shuffle_Nodes;

   function Default_Order (G : Graph) return Node_Array is
   begin
      if G'Length = 0 then
         declare
            Empty : Node_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;
      declare
         O : Node_Array (G'Range);
      begin
         for N in G'Range loop
            O (N) := N;
         end loop;
         return O;
      end;
   end Default_Order;

   -------------------------------------------------------------------------
   -- Core update
   -------------------------------------------------------------------------

   procedure Update_Node_Label
     (G       : Graph;
      Labels  : in out Label_Array;
      N       : Node_Id;
      State   : in out RNG_State;
      Changed : out Boolean)
   is
      Best_Score : Weight := 0.0;
      Tie_Labels : array (1 .. Max_Degree) of Label_Id;
      Tie_Count  : Natural := 0;
      L          : Label_Id;
      S          : Weight;
      Seen       : array (Node_Id) of Boolean := [others => False];
      Pick       : Natural;
      Old        : Label_Id;
   begin
      Changed := False;
      if N not in G'Range then
         raise Invalid_Argument with "Update_Node_Label: node out of range";
      end if;
      Require_Labels_Aligned (G, Labels);

      if G (N).Degree = 0 then
         return;
      end if;

      for I in 1 .. G (N).Degree loop
         L := Labels (G (N).Nodes (I));
         if not Seen (L) then
            Seen (L) := True;
            S := Neighbor_Label_Score (G, Labels, N, L);
            if Tie_Count = 0 or else S > Best_Score then
               Best_Score := S;
               Tie_Count := 1;
               Tie_Labels (1) := L;
            elsif S = Best_Score then
               Tie_Count := Tie_Count + 1;
               Tie_Labels (Tie_Count) := L;
            end if;
         end if;
      end loop;

      if Tie_Count = 0 then
         return;
      end if;

      if Tie_Count = 1 then
         Pick := 1;
      else
         Pick := (Next_Random (State) mod Tie_Count) + 1;
      end if;

      Old := Labels (N);
      Labels (N) := Tie_Labels (Pick);
      Changed := Labels (N) /= Old;
   end Update_Node_Label;

   -------------------------------------------------------------------------
   -- Driver
   -------------------------------------------------------------------------

   function Run_Internal
     (G           : Graph;
      Params      : Parameters;
      Fixed_Order : Node_Array;
      Use_Fixed   : Boolean) return Result
   is
      Labels       : Label_Array := Init_Labels (G);
      State        : RNG_State := Init_RNG (Params.Seed);
      Tie_State    : RNG_State := Init_RNG (Params.Seed);
      Any_Changed  : Boolean;
      Node_Changed : Boolean;
      Sweep        : Natural := 0;
      Converged    : Boolean := False;
   begin
      if G'Length = 0 then
         declare
            R : Result (1, 0);
         begin
            R.Iters := 0;
            R.Converged := True;
            R.Cluster_Count := 0;
            return R;
         end;
      end if;

      if Use_Fixed and then not Is_Permutation (G, Fixed_Order) then
         raise Invalid_Argument
           with "Run_Chinese_Whispers: Order is not a permutation of nodes";
      end if;

      declare
         Order : Node_Array :=
           (if Use_Fixed then Fixed_Order else Default_Order (G));
      begin
         for Iter in 1 .. Params.Max_Iters loop
            if not Use_Fixed then
               Order := Default_Order (G);
               Shuffle_Nodes (Order, State);
            end if;

            Any_Changed := False;
            for I in Order'Range loop
               Update_Node_Label
                 (G, Labels, Order (I), Tie_State, Node_Changed);
               if Node_Changed then
                  Any_Changed := True;
               end if;
            end loop;

            Sweep := Iter;
            if not Any_Changed then
               Converged := True;
               exit;
            end if;
         end loop;
      end;

      if Params.Relabel_Clusters then
         Relabel_Contiguous (Labels);
      end if;

      declare
         R : Result (G'First, G'Last);
      begin
         R.Labels := Labels;
         R.Iters := Sweep;
         R.Converged := Converged;
         R.Cluster_Count := Cluster_Count (Labels);
         return R;
      end;
   end Run_Internal;

   function Run_Chinese_Whispers
     (G      : Graph;
      Params : Parameters := Default_Parameters) return Result
   is
      Dummy : Node_Array (1 .. 0);
   begin
      return Run_Internal (G, Params, Dummy, Use_Fixed => False);
   end Run_Chinese_Whispers;

   function Run_Chinese_Whispers
     (G      : Graph;
      Order  : Node_Array;
      Params : Parameters := Default_Parameters) return Result
   is
   begin
      return Run_Internal (G, Params, Order, Use_Fixed => True);
   end Run_Chinese_Whispers;

end Chinese_Whispers;
