--  DBSCAN body — density-based clustering (Ester et al. 1996).

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body DBSCAN
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   procedure Require_Params (Params : Parameters) is
      pragma Unreferenced (Params);
   begin
      --  Parameters.Eps is Positive_Real and MinPts is Positive; invalid
      --  values are rejected at Make_Parameters / aggregate constraint.
      null;
   end Require_Params;

   procedure Require_Point (Data : Dataset; P : Point_Id) is
   begin
      if P not in Data'Range (1) then
         raise Invalid_Argument with "point id out of range";
      end if;
   end Require_Point;

   procedure Require_Capacity (Data : Dataset) is
   begin
      if Data'Length (1) > Max_Points then
         raise Capacity_Exceeded with "too many points";
      end if;
      if Data'Length (2) > Max_Dims then
         raise Capacity_Exceeded with "too many dimensions";
      end if;
      if Data'Length (1) = 0 or else Data'Length (2) = 0 then
         raise Invalid_Argument with "empty dataset";
      end if;
   end Require_Capacity;

   ---------------------------------------------------------------------------
   -- Near / Make_Parameters
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Make_Parameters
     (Eps : Real; MinPts : Integer) return Parameters
   is
   begin
      if Eps <= 0.0 then
         raise Invalid_Argument with "Eps must be > 0";
      end if;
      if MinPts < 1 then
         raise Invalid_Argument with "MinPts must be >= 1";
      end if;
      return (Eps => Positive_Real (Eps), MinPts => Positive (MinPts));
   end Make_Parameters;

   ---------------------------------------------------------------------------
   -- Distance / neighborhood
   ---------------------------------------------------------------------------

   function Distance
     (Data : Dataset;
      P, Q : Point_Id) return Non_Negative
   is
      Sum : Real := 0.0;
      Diff : Real;
   begin
      Require_Point (Data, P);
      Require_Point (Data, Q);
      for D in Data'Range (2) loop
         Diff := Data (P, D) - Data (Q, D);
         Sum := Sum + Diff * Diff;
      end loop;
      return Non_Negative (Math.Sqrt (Sum));
   end Distance;

   function Neighbor_Count
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Natural
   is
      Count : Natural := 0;
   begin
      Require_Point (Data, P);
      for Q in Data'Range (1) loop
         if Distance (Data, P, Q) <= Eps then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Neighbor_Count;

   function Range_Query
     (Data : Dataset;
      P    : Point_Id;
      Eps  : Positive_Real) return Point_Id_Array
   is
      Count : constant Natural := Neighbor_Count (Data, P, Eps);
      Nbr   : Point_Id_Array (1 .. Count);
      Ix    : Natural := 0;
   begin
      for Q in Data'Range (1) loop
         if Distance (Data, P, Q) <= Eps then
            Ix := Ix + 1;
            Nbr (Ix) := Q;
         end if;
      end loop;
      return Nbr;
   end Range_Query;

   function Is_Core_Point
     (Data   : Dataset;
      P      : Point_Id;
      Params : Parameters) return Boolean
   is
   begin
      Require_Point (Data, P);
      Require_Params (Params);
      return Neighbor_Count (Data, P, Params.Eps) >= Params.MinPts;
   end Is_Core_Point;

   ---------------------------------------------------------------------------
   -- Cluster / noise counts
   ---------------------------------------------------------------------------

   function Cluster_Count_Of (Lab : Labels) return Natural is
      Seen : array (1 .. Max_Points) of Boolean := [others => False];
      C    : Natural := 0;
      Id   : Integer;
   begin
      for I in Lab'Range loop
         Id := Lab (I);
         if Id > 0 and then Id <= Max_Points and then not Seen (Id) then
            Seen (Id) := True;
            C := C + 1;
         end if;
      end loop;
      return C;
   end Cluster_Count_Of;

   function Noise_Count_Of (Lab : Labels) return Natural is
      N : Natural := 0;
   begin
      for I in Lab'Range loop
         if Lab (I) = Noise_Label then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Noise_Count_Of;

   ---------------------------------------------------------------------------
   -- Run_DBSCAN (Wikipedia / Ester et al. query-based algorithm)
   ---------------------------------------------------------------------------

   function Run_DBSCAN
     (Data   : Dataset;
      Params : Parameters) return Result
   is
      First : constant Point_Id := Data'First (1);
      Last  : constant Natural  := Natural (Data'Last (1));
      N     : constant Point_Count := Point_Count (Data'Length (1));

      Lab : Labels (First .. Last);
      Kind : Point_Kind_Array (First .. Last);

      --  Working seed set: append-only list (duplicates OK; skipped when
      --  already labeled).  Size ≤ N * N in worst case; cap at Max_Points^2
      --  is too large — use a visited-in-seed flag + bounded queue of N.
      --  Union semantics: only enqueue points not yet in the seed queue.
      Seed_Q   : array (1 .. Max_Points) of Point_Id;
      Seed_Len : Natural := 0;
      In_Seed  : array (1 .. Max_Points) of Boolean := [others => False];

      C_Id : Cluster_Label := 0;
      Outcome : Result (First, Last);

      procedure Seed_Clear is
      begin
         for I in 1 .. Seed_Len loop
            In_Seed (Seed_Q (I)) := False;
         end loop;
         Seed_Len := 0;
      end Seed_Clear;

      procedure Seed_Add (Q : Point_Id) is
      begin
         if not In_Seed (Q) then
            if Seed_Len >= Max_Points then
               raise Capacity_Exceeded with "seed set overflow";
            end if;
            Seed_Len := Seed_Len + 1;
            Seed_Q (Seed_Len) := Q;
            In_Seed (Q) := True;
         end if;
      end Seed_Add;

      procedure Classify_Kinds is
      begin
         for P in First .. Last loop
            if Lab (P) = Noise_Label or else Lab (P) = Undefined_Label then
               Kind (P) := Noise_Kind;
               if Lab (P) = Undefined_Label then
                  Lab (P) := Noise_Label;
               end if;
            elsif Is_Core_Point (Data, P, Params) then
               Kind (P) := Core_Kind;
            else
               Kind (P) := Border_Kind;
            end if;
         end loop;
      end Classify_Kinds;

   begin
      Require_Capacity (Data);
      Require_Params (Params);
      pragma Unreferenced (N);

      for P in First .. Last loop
         Lab (P) := Undefined_Label;
         Kind (P) := Undefined_Kind;
      end loop;

      --  DBSCAN(DB, eps, minPts)
      for P in First .. Last loop
         if Lab (P) = Undefined_Label then
            declare
               N_P : constant Point_Id_Array :=
                 Range_Query (Data, P, Params.Eps);
            begin
               if N_P'Length < Params.MinPts then
                  Lab (P) := Noise_Label;
               else
                  C_Id := C_Id + 1;
                  Lab (P) := C_Id;
                  Seed_Clear;
                  --  SeedSet S := N \ {P}
                  for K in N_P'Range loop
                     if N_P (K) /= P then
                        Seed_Add (N_P (K));
                     end if;
                  end loop;

                  --  for each Q in S (index grows as we union)
                  declare
                     Si : Natural := 1;
                  begin
                     while Si <= Seed_Len loop
                        declare
                           Q : constant Point_Id := Seed_Q (Si);
                        begin
                           if Lab (Q) = Noise_Label then
                              --  Change Noise to border point of cluster C
                              Lab (Q) := C_Id;
                           end if;
                           if Lab (Q) = Undefined_Label then
                              Lab (Q) := C_Id;
                              declare
                                 N_Q : constant Point_Id_Array :=
                                   Range_Query (Data, Q, Params.Eps);
                              begin
                                 if N_Q'Length >= Params.MinPts then
                                    --  S := S ∪ N
                                    for K in N_Q'Range loop
                                       Seed_Add (N_Q (K));
                                    end loop;
                                 end if;
                              end;
                           end if;
                        end;
                        Si := Si + 1;
                     end loop;
                  end;
               end if;
            end;
         end if;
      end loop;

      Classify_Kinds;

      Outcome.Lab := Lab;
      Outcome.Kind := Kind;
      Outcome.Cluster_Count := Cluster_Count_Of (Lab);
      Outcome.Noise_Count := Noise_Count_Of (Lab);
      return Outcome;
   end Run_DBSCAN;

end DBSCAN;
