--  Grid_Search implementation: axis builders, cardinality, lex enumeration,
--  exhaustive Minimize / Maximize / Search.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Grid_Search
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Sense_Flag : Sense := Minimize_Sense) return Config
   is
   begin
      return (Sense_Flag => Sense_Flag);
   end Default_Config;

   function Better
     (Candidate, Incumbent : Real; Sense_Flag : Sense) return Boolean
   is
   begin
      case Sense_Flag is
         when Minimize_Sense =>
            return Candidate < Incumbent;
         when Maximize_Sense =>
            return Candidate > Incumbent;
      end case;
   end Better;

   ---------------------------------------------------------------------------
   -- Axis construction
   ---------------------------------------------------------------------------

   procedure Sort_Unique_In_Place
     (Buf   : in out Value_Array;
      Count : in out Axis_Size)
   is
      Tmp : Real;
      J   : Natural;
      W   : Axis_Size;
   begin
      --  Insertion sort ascending.
      for I in 2 .. Count loop
         Tmp := Buf (I);
         J := I - 1;
         while J >= 1 and then Buf (J) > Tmp loop
            Buf (J + 1) := Buf (J);
            J := J - 1;
         end loop;
         Buf (J + 1) := Tmp;
      end loop;

      --  Compact near-duplicates.
      if Count = 0 then
         return;
      end if;
      W := 1;
      for I in 2 .. Count loop
         if not Near (Buf (I), Buf (W)) then
            W := W + 1;
            Buf (W) := Buf (I);
         end if;
      end loop;
      Count := W;
   end Sort_Unique_In_Place;

   function Build_Axis (Raw : Value_Array) return Axis is
      A : Axis;
      N : constant Axis_Size := Axis_Size (Raw'Length);
   begin
      for I in 1 .. N loop
         A.Values (I) := Raw (Raw'First + (I - 1));
      end loop;
      A.Count := N;
      Sort_Unique_In_Place (A.Values, A.Count);
      if A.Count = 0 then
         raise Invalid_Argument;
      end if;
      return A;
   end Build_Axis;

   function Build_Linspace_Axis
     (Lo, Hi : Real; N : Axis_Index) return Axis
   is
      A : Axis;
      Den : Real;
   begin
      if Lo > Hi then
         raise Invalid_Argument;
      end if;
      A.Count := N;
      if N = 1 then
         A.Values (1) := Lo;
         return A;
      end if;
      Den := Real (N - 1);
      for I in 1 .. N loop
         A.Values (I) := Lo + (Hi - Lo) * Real (I - 1) / Den;
      end loop;
      --  Force exact endpoints (avoid FP drift).
      A.Values (1) := Lo;
      A.Values (N) := Hi;
      return A;
   end Build_Linspace_Axis;

   function Make_Grid (Axes : Axis_Array) return Grid is
      G : Grid;
      D : constant Dim_Count := Dim_Count (Axes'Length);
   begin
      if D = 0 then
         raise Invalid_Argument;
      end if;
      G.Dim := D;
      for I in 1 .. D loop
         G.Axes (I) := Axes (Axes'First + (I - 1));
         if G.Axes (I).Count = 0 then
            raise Invalid_Argument;
         end if;
      end loop;
      return G;
   end Make_Grid;

   function Axis_Length (A : Axis) return Axis_Size is
   begin
      return A.Count;
   end Axis_Length;

   function Get_Value (A : Axis; I : Axis_Index) return Real is
   begin
      if I > A.Count then
         raise Invalid_Argument;
      end if;
      return A.Values (I);
   end Get_Value;

   ---------------------------------------------------------------------------
   -- Cardinality / Point_At / Enumerate
   ---------------------------------------------------------------------------

   function Cardinality (G : Grid) return Natural is
      Prod : Natural := 1;
   begin
      if G.Dim = 0 then
         return 0;
      end if;
      for I in 1 .. G.Dim loop
         if G.Axes (I).Count = 0 then
            return 0;
         end if;
         --  Product fits comfortably: 16^6 = 16_777_216.
         Prod := Prod * Natural (G.Axes (I).Count);
      end loop;
      return Prod;
   end Cardinality;

   function Point_At (G : Grid; Rank : Positive) return Point is
      X       : Point (1 .. G.Dim);
      Rem_Idx : Natural;
      Idx     : Natural;
      Sz      : Natural;
   begin
      if G.Dim = 0 or else Rank > Cardinality (G) then
         raise Invalid_Argument;
      end if;
      --  Rank is 1-based; convert to 0-based mixed radix (last axis fastest).
      Rem_Idx := Rank - 1;
      for D in reverse 1 .. G.Dim loop
         Sz := Natural (G.Axes (D).Count);
         Idx := Rem_Idx mod Sz;
         Rem_Idx := Rem_Idx / Sz;
         X (D) := G.Axes (D).Values (Axis_Index (Idx + 1));
      end loop;
      return X;
   end Point_At;

   procedure Enumerate (G : Grid) is
      Total : Natural;
      Stop  : Boolean := False;
      X     : Point (1 .. Max_Dim);
      --  Odometer indices 1 .. Count per axis.
      Idx   : array (1 .. Max_Dim) of Axis_Index := [others => 1];
      Rank  : Positive;
   begin
      if G.Dim = 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. G.Dim loop
         if G.Axes (I).Count = 0 then
            raise Invalid_Argument;
         end if;
      end loop;

      Total := Cardinality (G);
      if Total = 0 then
         raise Invalid_Argument;
      end if;

      for I in 1 .. G.Dim loop
         Idx (I) := 1;
         X (I) := G.Axes (I).Values (1);
      end loop;

      Rank := 1;
      loop
         declare
            Slice : constant Point := X (1 .. G.Dim);
         begin
            Visit (Slice, Rank, Stop);
         end;
         exit when Stop or else Rank = Total;

         --  Advance odometer (last axis fastest).
         declare
            D : Dim_Index := G.Dim;
         begin
            loop
               if Idx (D) < G.Axes (D).Count then
                  Idx (D) := Idx (D) + 1;
                  X (D) := G.Axes (D).Values (Idx (D));
                  exit;
               else
                  Idx (D) := 1;
                  X (D) := G.Axes (D).Values (1);
                  exit when D = 1;
                  D := D - 1;
               end if;
            end loop;
         end;
         Rank := Rank + 1;
      end loop;
   end Enumerate;

   ---------------------------------------------------------------------------
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for V of X loop
         S := S + V * V;
      end loop;
      return S;
   end Sphere;

   function Multimodal_1D (X : Point) return Real is
      T : Real;
   begin
      if X'Length < 1 then
         raise Invalid_Argument;
      end if;
      T := X (X'First);
      return (T - 0.2) * (T - 0.2) * (T - 0.8) * (T - 0.8)
        - 0.05 * (T - 0.5) * (T - 0.5);
   end Multimodal_1D;

   function Neg_Sphere (X : Point) return Real is
   begin
      return -Sphere (X);
   end Neg_Sphere;

   function SVM_Toy_Score (X : Point) return Real is
      C, G, LC, LG : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      C := X (X'First);
      G := X (X'First + 1);
      if C <= 0.0 or else G <= 0.0 then
         return Real'First / 4.0;
      end if;
      LC := Math.Log (C, 10.0);
      LG := Math.Log (G, 10.0);
      --  Peak near C=100 (log10=2), γ=0.1 (log10=-1).
      return -(LC - 2.0) * (LC - 2.0) - 4.0 * (LG + 1.0) * (LG + 1.0);
   end SVM_Toy_Score;

   function Shifted_Sphere (X : Point) return Real is
      S : Real := 0.0;
      D : Real;
   begin
      for V of X loop
         D := V - 1.0;
         S := S + D * D;
      end loop;
      return S;
   end Shifted_Sphere;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search
     (Objective : Objective_Fn;
      G         : Grid;
      Cfg       : Config := Default_Config) return Result
   is
      R          : Result;
      First      : Boolean := True;
      Incumbent  : Real := 0.0;
      Total      : Natural;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if G.Dim = 0 then
         raise Invalid_Argument;
      end if;
      for I in 1 .. G.Dim loop
         if G.Axes (I).Count = 0 then
            raise Invalid_Argument;
         end if;
      end loop;

      Total := Cardinality (G);
      R.Dim := G.Dim;
      R.Evaluations := 0;
      R.Best_Rank := 0;

      for Rank in 1 .. Total loop
         declare
            X : constant Point := Point_At (G, Rank);
            F : constant Real := Objective (X);
         begin
            R.Evaluations := R.Evaluations + 1;
            if First or else Better (F, Incumbent, Cfg.Sense_Flag) then
               First := False;
               Incumbent := F;
               R.Best_F := F;
               R.Best_Rank := Rank;
               for D in 1 .. G.Dim loop
                  R.Best_X (D) := X (D);
               end loop;
               for D in G.Dim + 1 .. Max_Dim loop
                  R.Best_X (D) := 0.0;
               end loop;
            end if;
         end;
      end loop;

      return R;
   end Search;

   function Minimize
     (Objective : Objective_Fn; G : Grid) return Result
   is
   begin
      return Search (Objective, G, Default_Config (Minimize_Sense));
   end Minimize;

   function Maximize
     (Objective : Objective_Fn; G : Grid) return Result
   is
   begin
      return Search (Objective, G, Default_Config (Maximize_Sense));
   end Maximize;

end Grid_Search;
