--  Kargers_Algorithm body — contraction via Union–Find, deterministic LCG,
--  Exact_Min_Cut by bipartition enumeration.

pragma Ada_2022;


package body Kargers_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Deterministic seeded LCG (Numerical Recipes style, 31-bit)
   ---------------------------------------------------------------------------

   type LCG_State is mod 2**31;

   Multiplier : constant LCG_State := 1_103_515_245;
   Increment  : constant LCG_State := 12_345;

   function Init_LCG (Seed : Natural) return LCG_State is
   begin
      if Seed = 0 then
         return 1;
      else
         --  Modular conversion folds Seed into 0 .. 2**31-1.
         return LCG_State (Seed);
      end if;
   end Init_LCG;

   procedure Next_LCG (State : in out LCG_State) is
   begin
      State := State * Multiplier + Increment;
   end Next_LCG;

   --  Uniform integer in 1 .. Bound inclusive (Bound ≥ 1).
   function Next_Bounded
     (State : in out LCG_State; Bound : Positive) return Positive
   is
      Raw : Natural;
   begin
      Next_LCG (State);
      Raw := Natural (State) mod Bound;
      return Raw + 1;
   end Next_Bounded;

   ---------------------------------------------------------------------------
   -- Union–Find helpers (package-body scratch; educational)
   ---------------------------------------------------------------------------

   type Parent_Array is array (Vertex_Id) of Vertex_Id;
   type Rank_Array is array (Vertex_Id) of Natural;

   function Find
     (Parent : in out Parent_Array; X : Vertex_Id) return Vertex_Id
   is
      R : Vertex_Id := X;
   begin
      while Parent (R) /= R loop
         R := Parent (R);
      end loop;
      --  Path compression
      declare
         Y : Vertex_Id := X;
         Next : Vertex_Id;
      begin
         while Parent (Y) /= R loop
            Next := Parent (Y);
            Parent (Y) := R;
            Y := Next;
         end loop;
      end;
      return R;
   end Find;

   procedure Union
     (Parent : in out Parent_Array;
      Rank   : in out Rank_Array;
      A, B   : Vertex_Id;
      Merged : out Boolean)
   is
      RA : constant Vertex_Id := Find (Parent, A);
      RB : constant Vertex_Id := Find (Parent, B);
   begin
      if RA = RB then
         Merged := False;
         return;
      end if;
      Merged := True;
      if Rank (RA) < Rank (RB) then
         Parent (RA) := RB;
      elsif Rank (RA) > Rank (RB) then
         Parent (RB) := RA;
      else
         Parent (RB) := RA;
         Rank (RA) := Rank (RA) + 1;
      end if;
   end Union;

   ---------------------------------------------------------------------------
   -- Graph API
   ---------------------------------------------------------------------------

   procedure Clear (G : in out Graph; Vertex_Count : Natural) is
   begin
      if Vertex_Count > Max_Vertices then
         raise Invalid_Argument;
      end if;
      G.N := Vertex_Count;
      G.M := 0;
   end Clear;

   procedure Add_Edge (G : in out Graph; U, V : Vertex_Id) is
   begin
      if G.N = 0
        or else Natural (U) > G.N
        or else Natural (V) > G.N
      then
         raise Invalid_Argument;
      end if;
      if U = V then
         raise Invalid_Argument;
      end if;
      if G.M = Max_Edges then
         raise Invalid_Argument;
      end if;
      G.M := G.M + 1;
      G.Edges (G.M) := (U => U, V => V);
   end Add_Edge;

   function Vertex_Count (G : Graph) return Natural is
   begin
      return G.N;
   end Vertex_Count;

   function Edge_Count (G : Graph) return Natural is
   begin
      return Natural (G.M);
   end Edge_Count;

   ---------------------------------------------------------------------------
   -- One contraction trial
   ---------------------------------------------------------------------------

   function Contract_Once (G : Graph; Seed : Natural) return Cut_Size is
      Parent : Parent_Array;
      Rank   : Rank_Array := [others => 0];
      State  : LCG_State := Init_LCG (Seed);
      Comps  : Natural;
      Live   : Natural;
      Pick   : Positive;
      Seen   : Natural;
      Merged : Boolean;
      Cut    : Natural := 0;
      RU, RV : Vertex_Id;
   begin
      if G.N < 2 then
         raise Invalid_Argument;
      end if;

      for V in 1 .. G.N loop
         Parent (Vertex_Id (V)) := Vertex_Id (V);
      end loop;
      Comps := G.N;

      while Comps > 2 loop
         --  Count live (non-loop) edges under current supernodes
         Live := 0;
         for I in 1 .. G.M loop
            RU := Find (Parent, G.Edges (I).U);
            RV := Find (Parent, G.Edges (I).V);
            if RU /= RV then
               Live := Live + 1;
            end if;
         end loop;

         if Live = 0 then
            --  Disconnected: remaining supernodes have no crossing edges;
            --  eventual cut size is 0.
            return 0;
         end if;

         Pick := Next_Bounded (State, Live);
         Seen := 0;
         for I in 1 .. G.M loop
            RU := Find (Parent, G.Edges (I).U);
            RV := Find (Parent, G.Edges (I).V);
            if RU /= RV then
               Seen := Seen + 1;
               if Seen = Pick then
                  Union (Parent, Rank, RU, RV, Merged);
                  if Merged then
                     Comps := Comps - 1;
                  end if;
                  exit;
               end if;
            end if;
         end loop;
      end loop;

      for I in 1 .. G.M loop
         RU := Find (Parent, G.Edges (I).U);
         RV := Find (Parent, G.Edges (I).V);
         if RU /= RV then
            Cut := Cut + 1;
         end if;
      end loop;

      return Cut_Size (Cut);
   end Contract_Once;

   ---------------------------------------------------------------------------
   -- Multi-trial Min_Cut
   ---------------------------------------------------------------------------

   function Min_Cut
     (G : Graph; Trials : Positive; Seed : Natural) return Cut_Size
   is
      Best : Cut_Size;
      C    : Cut_Size;
      S    : Natural;
   begin
      if G.N < 2 then
         raise Invalid_Argument;
      end if;

      Best := Cut_Size'Last;
      for T in 1 .. Trials loop
         S := Seed + (T - 1);
         C := Contract_Once (G, S);
         if C < Best then
            Best := C;
         end if;
      end loop;
      return Best;
   end Min_Cut;

   ---------------------------------------------------------------------------
   -- Exact min-cut via bipartition enumeration (N ≤ Exact_Max_Vertices)
   ---------------------------------------------------------------------------

   function Exact_Min_Cut (G : Graph) return Cut_Size is
      N    : constant Natural := G.N;
      Best : Natural;
      Cut  : Natural;
      --  Bit k (0-based) of Mask says whether vertex (k+2) is in S.
      --  Vertex 1 is always in S. Skip the full-set mask.
      Max_Mask : Natural;
      In_S     : array (1 .. Exact_Max_Vertices) of Boolean;
   begin
      if N < 2 or else N > Exact_Max_Vertices then
         raise Invalid_Argument;
      end if;

      Best := Natural'Last;
      Max_Mask := 2 ** (N - 1) - 1;

      for Mask in 0 .. Max_Mask - 1 loop
         In_S := [others => False];
         In_S (1) := True;
         for K in 0 .. N - 2 loop
            if (Mask / (2 ** K)) mod 2 = 1 then
               In_S (K + 2) := True;
            end if;
         end loop;

         Cut := 0;
         for I in 1 .. G.M loop
            declare
               U : constant Natural := Natural (G.Edges (I).U);
               V : constant Natural := Natural (G.Edges (I).V);
            begin
               if In_S (U) /= In_S (V) then
                  Cut := Cut + 1;
               end if;
            end;
         end loop;

         if Cut < Best then
            Best := Cut;
         end if;
      end loop;

      return Cut_Size (Best);
   end Exact_Min_Cut;

end Kargers_Algorithm;
