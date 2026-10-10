pragma Ada_2022;
package body Connected_Component_Labeling
  with SPARK_Mode => On
is
   --  Runtime cost: the loop invariants quantify over the whole grid (all
   --  proved; not executed). The spec Posts still run.
   pragma Assertion_Policy (Loop_Invariant => Ignore);

   subtype Prov_Label is Positive range 1 .. Max_Rows * Max_Cols;
   type Parent_Array is array (Prov_Label) of Label_Id;

   --  Parent (L) <= L for every provisional label 1 .. Next (a root points
   --  to itself), so following parents always ends.
   function Forest (Parent : Parent_Array; Next : Label_Id) return Boolean is
     (for all L in 1 .. Next => Parent (L) in 1 .. L);

   --  Root of L, halving the path on the way (roots do not change).
   procedure Find (Parent : in out Parent_Array; Next : Label_Id; L : Prov_Label; Root : out Prov_Label)
     with Pre  => Forest (Parent, Next) and then L <= Next,
          Post => Forest (Parent, Next) and then Root <= L and then Parent (Root) = Root
   is
      Y : Prov_Label := L;
   begin
      while Parent (Y) /= Y loop
         pragma Loop_Invariant (Forest (Parent, Next) and then Y <= L);
         pragma Loop_Variant (Decreases => Y);
         Parent (Y) := Parent (Parent (Y));
         Y := Parent (Y);
      end loop;
      Root := Y;
   end Find;

   --  Join the trees of A and B: the larger root points to the smaller.
   procedure Union (Parent : in out Parent_Array; Next : Label_Id; A, B : Prov_Label)
     with Pre  => Forest (Parent, Next) and then A <= Next and then B <= Next,
          Post => Forest (Parent, Next)
   is
      RA, RB : Prov_Label;
   begin
      Find (Parent, Next, A, RA);
      Find (Parent, Next, B, RB);
      if RA < RB then
         Parent (RB) := RA;
      elsif RB < RA then
         Parent (RA) := RB;
      end if;
   end Union;

   procedure Label_Region
     (Input  : Binary_Grid;
      Rows   : Row_Count;
      Cols   : Col_Count;
      Output : out Label_Grid;
      Count  : out Label_Id)
   is
      Prov   : Label_Grid := [others => [others => 0]];
      Parent : Parent_Array := [others => 0];
      Map    : Parent_Array := [others => 0];   --  root -> compact id
      Next   : Label_Id := 0;
      N, W   : Label_Id;
      Rt     : Prov_Label;
   begin
      --  Pass 1: provisional labels; equal labels of touching N / W
      --  neighbours are joined. The bounds use Max_Cols (not Cols) so they
      --  stay linear: at most one new label per cell.
      for R in 1 .. Rows loop
         pragma Loop_Invariant (Next <= (R - 1) * Max_Cols);
         pragma Loop_Invariant (Forest (Parent, Next));
         pragma Loop_Invariant
           (for all R2 in Row_Index => (for all C2 in Col_Index => Prov (R2, C2) <= Next));
         pragma Loop_Invariant
           (for all R2 in Row_Index => (for all C2 in Col_Index =>
              (if R2 < R and then C2 <= Cols then (Prov (R2, C2) = 0) = not Input (R2, C2)
               else Prov (R2, C2) = 0)));
         for C in 1 .. Cols loop
            pragma Loop_Invariant (Next <= (R - 1) * Max_Cols + (C - 1));
            pragma Loop_Invariant (Forest (Parent, Next));
            pragma Loop_Invariant
              (for all R2 in Row_Index => (for all C2 in Col_Index => Prov (R2, C2) <= Next));
            pragma Loop_Invariant
              (for all R2 in Row_Index => (for all C2 in Col_Index =>
                 (if C2 <= Cols and then (R2 < R or else (R2 = R and then C2 < C))
                  then (Prov (R2, C2) = 0) = not Input (R2, C2)
                  else Prov (R2, C2) = 0)));
            if Input (R, C) then
               N := (if R > 1 then Prov (R - 1, C) else 0);
               W := (if C > 1 then Prov (R, C - 1) else 0);
               if N = 0 and then W = 0 then
                  Next := Next + 1;
                  Parent (Next) := Next;
                  Prov (R, C) := Next;
               elsif N /= 0 and then W /= 0 then
                  Union (Parent, Next, N, W);
                  Prov (R, C) := N;
               else
                  Prov (R, C) := Label_Id'Max (N, W);
               end if;
            end if;
         end loop;
      end loop;

      --  Pass 2: each root gets the next compact id, in scan order.
      Output := [others => [others => 0]];
      Count := 0;
      for R in 1 .. Rows loop
         pragma Loop_Invariant (Count <= (R - 1) * Max_Cols);
         pragma Loop_Invariant (Forest (Parent, Next));
         pragma Loop_Invariant (for all L in Prov_Label => Map (L) <= Count);
         pragma Loop_Invariant
           (for all R2 in Row_Index => (for all C2 in Col_Index =>
              Output (R2, C2) <= Count
              and then (if R2 < R and then C2 <= Cols then (Output (R2, C2) = 0) = (Prov (R2, C2) = 0)
                        else Output (R2, C2) = 0)));
         for C in 1 .. Cols loop
            pragma Loop_Invariant (Count <= (R - 1) * Max_Cols + (C - 1));
            pragma Loop_Invariant (Forest (Parent, Next));
            pragma Loop_Invariant (for all L in Prov_Label => Map (L) <= Count);
            pragma Loop_Invariant
              (for all R2 in Row_Index => (for all C2 in Col_Index =>
                 Output (R2, C2) <= Count
                 and then (if C2 <= Cols and then (R2 < R or else (R2 = R and then C2 < C))
                           then (Output (R2, C2) = 0) = (Prov (R2, C2) = 0)
                           else Output (R2, C2) = 0)));
            if Prov (R, C) /= 0 then
               Find (Parent, Next, Prov (R, C), Rt);
               if Map (Rt) = 0 then
                  Count := Count + 1;
                  Map (Rt) := Count;
               end if;
               Output (R, C) := Map (Rt);
            end if;
         end loop;
      end loop;
   end Label_Region;

   procedure Label
     (Input  : Binary_Grid;
      Output : out Label_Grid;
      Count  : out Label_Id)
   is
   begin
      Label_Region (Input, Max_Rows, Max_Cols, Output, Count);
   end Label;

   function Component_Count (Labels : Label_Grid) return Label_Id is
      Max_Found : Label_Id := 0;
   begin
      for R in Row_Index loop
         for C in Col_Index loop
            if Labels (R, C) > Max_Found then
               Max_Found := Labels (R, C);
            end if;
         end loop;
      end loop;
      return Max_Found;
   end Component_Count;

end Connected_Component_Labeling;
