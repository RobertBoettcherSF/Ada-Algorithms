--  WACA_Clustering body — unit-disk / neighbor graphs, weight components,
--  Fig.1 election, king bonus, hierarchy walk.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body WACA_Clustering
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Contains (N : Node_Neighbors; Id : Device_Id) return Boolean is
   begin
      for I in 1 .. N.Degree loop
         if N.List (I) = Id then
            return True;
         end if;
      end loop;
      return False;
   end Contains;

   procedure Append_Neighbor (N : in out Node_Neighbors; Id : Device_Id) is
   begin
      if Contains (N, Id) then
         return;
      end if;
      if N.Degree = Max_Nodes - 1 then
         raise Capacity_Exceeded with "neighbor list full";
      end if;
      N.Degree := N.Degree + 1;
      N.List (N.Degree) := Id;
   end Append_Neighbor;

   function Euclidean (A, B : Position) return Non_Negative is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return Non_Negative (Math.Sqrt (Float (DX * DX + DY * DY)));
   end Euclidean;

   procedure Require_Aligned (G : Graph; Attrs : Attrs_Array) is
   begin
      if Attrs'First /= G'First or else Attrs'Last /= G'Last then
         raise Invalid_Argument with "Attrs range must match Graph";
      end if;
   end Require_Aligned;

   procedure Require_Nonneg_Factors (F : Weight_Factors) is
   begin
      if F.Wf1 < 0.0 or else F.Wf2 < 0.0
        or else F.Wf3 < 0.0 or else F.Wf4 < 0.0
      then
         raise Invalid_Argument with "weight factors must be >= 0";
      end if;
   end Require_Nonneg_Factors;

   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Degree (G : Graph; D : Device_Id) return Natural is
   begin
      if D not in G'Range then
         raise Invalid_Argument with "Degree: device id out of range";
      end if;
      return Natural (G (D).Degree);
   end Degree;

   -------------------------------------------------------------------------
   -- Graph construction
   -------------------------------------------------------------------------

   function Empty_Graph (N : Node_Count) return Graph is
   begin
      --  N is constrained to 0 .. Max_Nodes by Node_Count.
      if N = 0 then
         declare
            --  Empty slice: First > Last is not representable with Device_Id
            --  subtype; use a zero-length array via aggregate trick.
            G : Graph (1 .. 0);
         begin
            return G;
         end;
      end if;
      declare
         G : Graph (1 .. Device_Id (N));
      begin
         for D in G'Range loop
            G (D).Degree := 0;
         end loop;
         return G;
      end;
   end Empty_Graph;

   procedure Add_Undirected_Edge
     (G : in out Graph; A, B : Device_Id)
   is
   begin
      if A not in G'Range or else B not in G'Range then
         raise Invalid_Argument with "Add_Undirected_Edge: id out of range";
      end if;
      if A = B then
         raise Invalid_Argument with "Add_Undirected_Edge: self-loop";
      end if;
      Append_Neighbor (G (A), B);
      Append_Neighbor (G (B), A);
   end Add_Undirected_Edge;

   function Build_Unit_Disk
     (Pos : Position_Array; Range_R : Non_Negative) return Graph
   is
      N : constant Natural := Pos'Length;
   begin
      if N > Max_Nodes then
         raise Capacity_Exceeded with "Build_Unit_Disk: too many nodes";
      end if;
      if Range_R < 0.0 then
         raise Degenerate_Geometry with "negative radio range";
      end if;
      declare
         G : Graph := Empty_Graph (Node_Count (N));
         --  Map Pos'Range onto 1 .. N for Device_Id indexing.
         Idx_Of : array (Pos'Range) of Device_Id;
         K      : Device_Id := 1;
      begin
         if N = 0 then
            return G;
         end if;
         for P in Pos'Range loop
            Idx_Of (P) := K;
            if K < Device_Id (N) then
               K := K + 1;
            end if;
         end loop;
         for I in Pos'Range loop
            for J in Pos'Range loop
               if I < J then
                  if Euclidean (Pos (I), Pos (J)) <= Range_R then
                     Add_Undirected_Edge (G, Idx_Of (I), Idx_Of (J));
                  end if;
               end if;
            end loop;
         end loop;
         return G;
      end;
   end Build_Unit_Disk;

   -------------------------------------------------------------------------
   -- Weight components
   -------------------------------------------------------------------------

   function Power_Appropriateness (P : Positive_Real) return Non_Negative is
   begin
      if P <= 0.0 then
         raise Invalid_Argument with "Power must be > 0";
      end if;
      --  PA = ln(1 + P); Ada Log is natural log on Float.
      return Non_Negative (Math.Log (Float (1.0 + P)));
   end Power_Appropriateness;

   function Dissemination_Degree_Score
     (Deg : Natural; Ideal : Natural) return Unit_Interval
   is
      Diff : constant Natural :=
        (if Deg >= Ideal then Deg - Ideal else Ideal - Deg);
   begin
      return Unit_Interval (1.0 / (1.0 + Real (Diff)));
   end Dissemination_Degree_Score;

   function Local_Clustering_Coefficient
     (G : Graph; D : Device_Id) return Unit_Interval
   is
      Deg : Natural;
      Edges_Among : Natural := 0;
      Possible    : Real;
      Ni, Nj      : Device_Id;
   begin
      if D not in G'Range then
         raise Invalid_Argument with "c_L: device id out of range";
      end if;
      Deg := Natural (G (D).Degree);
      if Deg < 2 then
         return 0.0;
      end if;
      --  Count undirected edges among neighbors of D.
      for I in 1 .. G (D).Degree loop
         Ni := G (D).List (I);
         if Ni in G'Range then
            for J in I + 1 .. G (D).Degree loop
               Nj := G (D).List (J);
               if Nj in G'Range and then Contains (G (Ni), Nj) then
                  Edges_Among := Edges_Among + 1;
               end if;
            end loop;
         end if;
      end loop;
      Possible := Real (Deg * (Deg - 1)) / 2.0;
      return Unit_Interval (Real (Edges_Among) / Possible);
   end Local_Clustering_Coefficient;

   function Compute_Weight
     (G       : Graph;
      D       : Device_Id;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors) return Real
   is
      A  : Node_Attrs;
      PA : Non_Negative;
      DD : Unit_Interval;
      CL : Unit_Interval;
      W0 : Real;
   begin
      Require_Aligned (G, Attrs);
      Require_Nonneg_Factors (Factors);
      if D not in G'Range then
         raise Invalid_Argument with "Compute_Weight: id out of range";
      end if;
      A := Attrs (D);
      if A.Power <= 0.0 then
         raise Invalid_Argument with "Power must be > 0";
      end if;
      if A.Signal < 0.0 or else A.Signal > 1.0 then
         raise Invalid_Argument with "Signal must be in [0,1]";
      end if;
      PA := Power_Appropriateness (A.Power);
      DD := Dissemination_Degree_Score (Degree (G, D), A.Ideal_Degree);
      CL := Local_Clustering_Coefficient (G, D);
      W0 := Factors.Wf1 * PA
          + Factors.Wf2 * A.Signal
          + Factors.Wf3 * DD
          + Factors.Wf4 * CL;
      return W0 + A.King_Bonus;
   end Compute_Weight;

   -------------------------------------------------------------------------
   -- Election
   -------------------------------------------------------------------------

   function Elect_Clusterheads
     (G       : Graph;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors) return WACA_Result
   is
   begin
      Require_Aligned (G, Attrs);
      Require_Nonneg_Factors (Factors);

      if G'Length = 0 then
         declare
            R : WACA_Result (First => 1, Last => 0);
         begin
            return R;
         end;
      end if;

      declare
         R : WACA_Result (First => G'First, Last => G'Last);
         Best_Id : Device_Id;
         Best_W  : Real;
         Cand_W  : Real;
         Is_SH   : Boolean;
         Nbr     : Device_Id;
      begin
         --  Weights
         for D in G'Range loop
            R.Weights (D) := Compute_Weight (G, D, Attrs, Factors);
         end loop;

         --  Each device elects highest-weight neighbor-or-self;
         --  ties → lowest Device_Id.
         for D in G'Range loop
            Best_Id := D;
            Best_W  := R.Weights (D);
            for I in 1 .. G (D).Degree loop
               Nbr := G (D).List (I);
               if Nbr in G'Range then
                  Cand_W := R.Weights (Nbr);
                  if Cand_W > Best_W
                    or else (Near (Cand_W, Best_W)
                             and then Nbr < Best_Id)
                  then
                     Best_W  := Cand_W;
                     Best_Id := Nbr;
                  end if;
               end if;
            end loop;
            R.Clusterhead_Of (D) := Best_Id;
         end loop;

         --  Roles
         for D in G'Range loop
            if R.Clusterhead_Of (D) = D then
               R.Role (D) := Clusterhead;
            else
               Is_SH := False;
               for I in 1 .. G (D).Degree loop
                  Nbr := G (D).List (I);
                  if Nbr in G'Range
                    and then R.Clusterhead_Of (Nbr) = D
                  then
                     Is_SH := True;
                     exit;
                  end if;
               end loop;
               if Is_SH then
                  R.Role (D) := Sub_Head;
               else
                  R.Role (D) := Slave;
               end if;
            end if;
         end loop;

         return R;
      end;
   end Elect_Clusterheads;

   function Run_WACA
     (G       : Graph;
      Attrs   : Attrs_Array;
      Factors : Weight_Factors := Default_Factors) return WACA_Result
   is
   begin
      return Elect_Clusterheads (G, Attrs, Factors);
   end Run_WACA;

   function Follow_To_Root
     (CH_Of : CH_Array; D : Device_Id) return Device_Id
   is
      Cur   : Device_Id := D;
      Steps : Natural := 0;
      Nxt   : Device_Id;
   begin
      if D not in CH_Of'Range then
         raise Invalid_Argument with "Follow_To_Root: id out of range";
      end if;
      loop
         Nxt := CH_Of (Cur);
         if Nxt not in CH_Of'Range then
            raise Degenerate_Geometry with "CH pointer out of range";
         end if;
         exit when Nxt = Cur;
         Steps := Steps + 1;
         if Steps > Max_Nodes then
            raise Degenerate_Geometry with "CH pointer cycle detected";
         end if;
         Cur := Nxt;
      end loop;
      return Cur;
   end Follow_To_Root;

   -------------------------------------------------------------------------
   -- King bonus
   -------------------------------------------------------------------------

   function Set_Diff_Size (A, B : Node_Neighbors) return Natural is
      --  |A \ B|
      Cnt : Natural := 0;
   begin
      for I in 1 .. A.Degree loop
         if not Contains (B, A.List (I)) then
            Cnt := Cnt + 1;
         end if;
      end loop;
      return Cnt;
   end Set_Diff_Size;

   function Stability_Coefficient
     (Old_N, New_N : Node_Neighbors) return Unit_Interval
   is
      Sym : constant Natural :=
        Set_Diff_Size (Old_N, New_N) + Set_Diff_Size (New_N, Old_N);
      Den : constant Natural :=
        Natural (Old_N.Degree) + Natural (New_N.Degree);
   begin
      if Den = 0 then
         return 0.0;
      end if;
      return Unit_Interval (Real (Sym) / Real (Den));
   end Stability_Coefficient;

   function Neighborhoods_Equal (A, B : Node_Neighbors) return Boolean is
   begin
      if A.Degree /= B.Degree then
         return False;
      end if;
      for I in 1 .. A.Degree loop
         if not Contains (B, A.List (I)) then
            return False;
         end if;
      end loop;
      return True;
   end Neighborhoods_Equal;

   procedure King_Bonus_Update
     (Attrs           : in out Attrs_Array;
      D               : Device_Id;
      Is_Clusterhead  : Boolean;
      Old_Neighbors   : Node_Neighbors;
      New_Neighbors   : Node_Neighbors)
   is
      K : Non_Negative;
      S : Unit_Interval;
   begin
      if D not in Attrs'Range then
         raise Invalid_Argument with "King_Bonus_Update: id out of range";
      end if;

      if not Is_Clusterhead then
         Attrs (D).King_Bonus := 0.0;
         return;
      end if;

      if New_Neighbors.Degree = 0 then
         Attrs (D).King_Bonus := 0.0;
         return;
      end if;

      K := Attrs (D).King_Bonus;
      if K >= King_Bonus_Max then
         --  Already at cap; still apply reduction on churn.
         if not Neighborhoods_Equal (Old_Neighbors, New_Neighbors) then
            S := Stability_Coefficient (Old_Neighbors, New_Neighbors);
            K := Non_Negative (K - K * S);
            Attrs (D).King_Bonus := K;
         end if;
         return;
      end if;

      if not Neighborhoods_Equal (Old_Neighbors, New_Neighbors) then
         S := Stability_Coefficient (Old_Neighbors, New_Neighbors);
         K := Non_Negative (K - K * S);
      else
         K := K + King_Bonus_Step;
         if K > King_Bonus_Max then
            K := King_Bonus_Max;
         end if;
      end if;
      Attrs (D).King_Bonus := K;
   end King_Bonus_Update;

end WACA_Clustering;
