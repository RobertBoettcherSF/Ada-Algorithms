--  Canopy_Clustering body — McCallum, Nigam, Ungar (2000) / Wikipedia.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Canopy_Clustering
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Make_Parameters (T1, T2 : Real) return Parameters is
   begin
      if T2 <= 0.0 or else T1 <= T2 then
         raise Invalid_Argument
           with "Make_Parameters: require T1 > T2 > 0";
      end if;
      return (T1 => Positive_Real (T1), T2 => Positive_Real (T2));
   end Make_Parameters;

   function Distance
     (Data : Dataset;
      P, Q : Point_Index) return Non_Negative
   is
      Sum : Real := 0.0;
      Diff : Real;
   begin
      if P not in Data'Range (1) or else Q not in Data'Range (1) then
         raise Invalid_Argument with "Distance: point index out of range";
      end if;
      for D in Data'Range (2) loop
         Diff := Data (P, D) - Data (Q, D);
         Sum := Sum + Diff * Diff;
      end loop;
      if Sum <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance;

   function Distance_To_Center
     (Data    : Dataset;
      P       : Point_Index;
      Centers : Canopy_Centers;
      C       : Canopy_Index) return Non_Negative
   is
      Sum : Real := 0.0;
      Diff : Real;
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument
           with "Distance_To_Center: point out of range";
      end if;
      if C not in Centers'Range (1) then
         raise Invalid_Argument
           with "Distance_To_Center: canopy out of range";
      end if;
      for D in Data'Range (2) loop
         Diff := Data (P, D) - Centers (C, D);
         Sum := Sum + Diff * Diff;
      end loop;
      if Sum <= 0.0 then
         return 0.0;
      end if;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance_To_Center;

   -------------------------------------------------------------------------
   -- Run_Canopy
   -------------------------------------------------------------------------

   function Run_Canopy
     (Data   : Dataset;
      Params : Parameters) return Result
   is
      N_Raw : constant Natural := Data'Length (1);
      D_Raw : constant Natural := Data'Length (2);
      N : Point_Count;
      Ddims : Dim_Count;
   begin
      if N_Raw > Max_Points then
         raise Capacity_Exceeded with "Run_Canopy: too many points";
      end if;
      if D_Raw > Max_Dims then
         raise Capacity_Exceeded with "Run_Canopy: too many dimensions";
      end if;
      if D_Raw = 0 then
         raise Invalid_Argument with "Run_Canopy: zero dimensions";
      end if;
      if Params.T2 <= 0.0 or else Params.T1 <= Params.T2 then
         raise Invalid_Argument with "Run_Canopy: require T1 > T2 > 0";
      end if;
      N := Point_Count (N_Raw);
      Ddims := Dim_Count (D_Raw);

      if N = 0 then
         declare
            Empty : Result (N => 0, C => 0, D => Ddims);
         begin
            Empty.Num_Canopies := 0;
            return Empty;
         end;
      end if;

      declare
         Work : Dataset (1 .. N, 1 .. Ddims);
         In_Pool : array (1 .. N) of Boolean := [others => True];
         Remaining : Natural := Natural (N);

         Tmp_Center_Ids : Center_Point_Ids (1 .. Max_Canopies);
         Tmp_Centers : Canopy_Centers (1 .. Max_Canopies, 1 .. Ddims);
         Tmp_Memb : Membership (1 .. N, 1 .. Max_Canopies) :=
           [others => [others => False]];
         Tmp_Lists : Membership_Lists (1 .. N) := [others => <>];
         C_Count : Canopy_Count := 0;

         function Next_Center return Point_Index is
         begin
            --  Stable ascending index order among remaining pool points.
            for P in 1 .. Point_Index (N) loop
               if In_Pool (P) then
                  return P;
               end if;
            end loop;
            raise Program_Error with "Next_Center: empty pool";
         end Next_Center;

         procedure Remove_From_Pool (P : Point_Index) is
         begin
            if In_Pool (P) then
               In_Pool (P) := False;
               Remaining := Remaining - 1;
            end if;
         end Remove_From_Pool;

         procedure Add_Membership (P : Point_Index; C : Canopy_Index) is
            L : Canopy_Membership_List renames Tmp_Lists (P);
         begin
            if not Tmp_Memb (P, C) then
               Tmp_Memb (P, C) := True;
               if L.Count = Max_Canopies then
                  raise Capacity_Exceeded
                    with "Run_Canopy: membership list full";
               end if;
               L.Count := L.Count + 1;
               L.Ids (L.Count) := C;
            end if;
         end Add_Membership;

      begin
         for P in 1 .. Point_Index (N) loop
            for Dim in 1 .. Dim_Index (Ddims) loop
               Work (P, Dim) :=
                 Data (Data'First (1) + (P - 1),
                       Data'First (2) + (Dim - 1));
            end loop;
         end loop;

         while Remaining > 0 loop
            declare
               Center : constant Point_Index := Next_Center;
               C_Id : Canopy_Index;
            begin
               if C_Count = Max_Canopies then
                  raise Capacity_Exceeded
                    with "Run_Canopy: Max_Canopies exceeded";
               end if;
               C_Count := C_Count + 1;
               C_Id := Canopy_Index (C_Count);
               Tmp_Center_Ids (C_Id) := Center;
               for Dim in 1 .. Dim_Index (Ddims) loop
                  Tmp_Centers (C_Id, Dim) := Work (Center, Dim);
               end loop;

               --  Center belongs to its own canopy and leaves the pool.
               Add_Membership (Center, C_Id);
               Remove_From_Pool (Center);

               --  Scan remaining points in ascending index order.
               for P in 1 .. Point_Index (N) loop
                  if In_Pool (P) then
                     declare
                        Dist : constant Non_Negative :=
                          Distance (Work, Center, P);
                     begin
                        if Dist < Params.T1 then
                           Add_Membership (P, C_Id);
                           if Dist < Params.T2 then
                              Remove_From_Pool (P);
                           end if;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end loop;

         declare
            R : Result (N => N, C => C_Count, D => Ddims);
         begin
            R.Num_Canopies := C_Count;
            if C_Count > 0 then
               for C in 1 .. Canopy_Index (C_Count) loop
                  R.Center_Ids (C) := Tmp_Center_Ids (C);
                  for Dim in 1 .. Dim_Index (Ddims) loop
                     R.Centers (C, Dim) := Tmp_Centers (C, Dim);
                  end loop;
                  for P in 1 .. Point_Index (N) loop
                     R.Memb (P, C) := Tmp_Memb (P, C);
                  end loop;
               end loop;
            end if;
            for P in 1 .. Point_Index (N) loop
               R.Lists (P) := Tmp_Lists (P);
            end loop;
            return R;
         end;
      end;
   end Run_Canopy;

   function Canopy_Count_Of (R : Result) return Canopy_Count is
   begin
      return R.Num_Canopies;
   end Canopy_Count_Of;

   function Point_In_Canopy
     (R : Result;
      P : Point_Index;
      C : Canopy_Index) return Boolean
   is
   begin
      if P not in 1 .. R.N or else C not in 1 .. R.C then
         raise Invalid_Argument with "Point_In_Canopy: index out of range";
      end if;
      return R.Memb (P, C);
   end Point_In_Canopy;

   function Canopies_Of
     (R : Result;
      P : Point_Index) return Canopy_Membership_List
   is
   begin
      if P not in 1 .. R.N then
         raise Invalid_Argument with "Canopies_Of: point out of range";
      end if;
      return R.Lists (P);
   end Canopies_Of;

   function Hard_Labels_Nearest_Center (R : Result; Data : Dataset)
     return Hard_Labels
   is
      Lab : Hard_Labels (1 .. R.N) := [others => 0];
   begin
      if R.N = 0 or else R.C = 0 then
         return Lab;
      end if;
      if Data'Length (1) /= R.N or else Data'Length (2) /= R.D then
         raise Invalid_Argument
           with "Hard_Labels_Nearest_Center: dataset shape mismatch";
      end if;

      for P in 1 .. Point_Index (R.N) loop
         declare
            Best_C : Natural := 0;
            Best_Sq : Real := Real'Last;
            Sq : Real;
            DP : constant Point_Index := Data'First (1) + (P - 1);
         begin
            for C in 1 .. Canopy_Index (R.C) loop
               if R.Memb (P, C) then
                  Sq := 0.0;
                  for Dim in 1 .. Dim_Index (R.D) loop
                     declare
                        Diff : constant Real :=
                          Data (DP, Data'First (2) + (Dim - 1))
                          - R.Centers (C, Dim);
                     begin
                        Sq := Sq + Diff * Diff;
                     end;
                  end loop;
                  --  Strictly nearer wins; equal distance → lowest canopy id.
                  if Best_C = 0
                    or else Sq < Best_Sq
                    or else (Near (Sq, Best_Sq)
                               and then Natural (C) < Best_C)
                  then
                     Best_Sq := Sq;
                     Best_C := Natural (C);
                  end if;
               end if;
            end loop;
            Lab (P) := Best_C;
         end;
      end loop;
      return Lab;
   end Hard_Labels_Nearest_Center;

   function Hard_Labels_First_Canopy (R : Result) return Hard_Labels is
      Lab : Hard_Labels (1 .. R.N) := [others => 0];
   begin
      if R.N = 0 or else R.C = 0 then
         return Lab;
      end if;
      for P in 1 .. Point_Index (R.N) loop
         if R.Lists (P).Count > 0 then
            Lab (P) := Natural (R.Lists (P).Ids (1));
         else
            for C in 1 .. Canopy_Index (R.C) loop
               if R.Memb (P, C) then
                  Lab (P) := Natural (C);
                  exit;
               end if;
            end loop;
         end if;
      end loop;
      return Lab;
   end Hard_Labels_First_Canopy;

end Canopy_Clustering;
