with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Self_Organizing_Map is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Data_Value);
   use Math;

   -- Internal Helper: Grid Distance computes spatial distance on the SOM lattice
   function Grid_Distance (C1, C2 : Coordinate) return Data_Value is
      DX : constant Data_Value := Data_Value (C1.X) - Data_Value (C2.X);
      DY : constant Data_Value := Data_Value (C1.Y) - Data_Value (C2.Y);
   begin
      return Sqrt (DX * DX + DY * DY);
   end Grid_Distance;

   procedure Initialize_Random
     (Map  : out SOM_Map;
      Seed : in  Integer)
   is
      Gen : Ada.Numerics.Float_Random.Generator;
   begin
      Ada.Numerics.Float_Random.Reset (Gen, Seed);
      for X in Map'Range(1) loop
         for Y in Map'Range(2) loop
            for F in Map'Range(3) loop
               Map(X, Y, F) := Data_Value (Ada.Numerics.Float_Random.Random (Gen));
            end loop;
         end loop;
      end loop;
   end Initialize_Random;

   function Euclidean_Distance (V1, V2 : Vector) return Data_Value is
      Sum  : Data_Value := 0.0;
      Diff : Data_Value;
   begin
      if V1'Length /= V2'Length then
         raise Dimension_Mismatch;
      end if;
      
      -- Safely iterate across vectors which might have different starting indices
      declare
         Idx2 : Feature_Index := V2'First;
      begin
         for Idx1 in V1'Range loop
            Diff := V1(Idx1) - V2(Idx2);
            Sum := Sum + (Diff * Diff);
            if Idx1 < V1'Last then
               Idx2 := Idx2 + 1;
            end if;
         end loop;
      end;
      return Sqrt (Sum);
   end Euclidean_Distance;

   function Extract_Vector (Map : SOM_Map; X : Grid_X; Y : Grid_Y) return Vector is
      Result : Vector (Map'Range(3));
   begin
      for F in Map'Range(3) loop
         Result(F) := Map(X, Y, F);
      end loop;
      return Result;
   end Extract_Vector;

   function Extract_Sample (Data : Dataset; Row : Sample_Index) return Vector is
      Result : Vector (Data'Range(2));
   begin
      for F in Data'Range(2) loop
         Result(F) := Data(Row, F);
      end loop;
      return Result;
   end Extract_Sample;

   function Find_BMU
     (Map : in SOM_Map;
      Vec : in Vector) return Coordinate
   is
      Min_Dist : Data_Value := Data_Value'Last;
      Current_Dist : Data_Value;
      BMU : Coordinate := (X => Map'First(1), Y => Map'First(2));
   begin
      if Map'Length(3) /= Vec'Length then
         raise Dimension_Mismatch;
      end if;

      for X in Map'Range(1) loop
         for Y in Map'Range(2) loop
            Current_Dist := Euclidean_Distance (Extract_Vector (Map, X, Y), Vec);
            if Current_Dist < Min_Dist then
               Min_Dist := Current_Dist;
               BMU := (X => X, Y => Y);
            end if;
         end loop;
      end loop;
      return BMU;
   end Find_BMU;

   procedure Train_Online
     (Map                   : in out SOM_Map;
      Data                  : in     Dataset;
      Epochs                : in     Positive;
      Initial_Learning_Rate : in     Data_Value;
      Initial_Radius        : in     Data_Value)
   is
      Learning_Rate : Data_Value;
      Radius        : Data_Value;
      Decay_Factor  : Data_Value;
      BMU           : Coordinate;
      Dist          : Data_Value;
      Theta         : Data_Value;
      Sample_Vec    : Vector (Data'Range(2));
   begin
      if Data'Length(1) = 0 then
         raise Empty_Dataset;
      end if;
      if Data'Length(2) /= Map'Length(3) then
         raise Dimension_Mismatch;
      end if;
      if Initial_Learning_Rate <= 0.0 or else Initial_Radius <= 0.0 then
         raise Invalid_Parameters;
      end if;

      for Epoch in 1 .. Epochs loop
         -- Exponential decay: reduces learning rate and neighborhood radius gradually
         Decay_Factor := Data_Value (Epoch - 1) / Data_Value (Epochs);
         Learning_Rate := Initial_Learning_Rate * Exp (-Decay_Factor * 5.0);
         Radius := Initial_Radius * Exp (-Decay_Factor * 5.0);

         for S in Data'Range(1) loop
            Sample_Vec := Extract_Sample (Data, S);
            BMU := Find_BMU (Map, Sample_Vec);

            for X in Map'Range(1) loop
               for Y in Map'Range(2) loop
                  Dist := Grid_Distance (BMU, (X => X, Y => Y));
                  if Dist < Radius then
                     -- Gaussian neighborhood function
                     Theta := Exp (-(Dist * Dist) / (2.0 * Radius * Radius));
                     for F in Map'Range(3) loop
                        Map(X, Y, F) := Map(X, Y, F) + Theta * Learning_Rate * (Sample_Vec(F) - Map(X, Y, F));
                     end loop;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
   end Train_Online;

   procedure Train_Batch
     (Map            : in out SOM_Map;
      Data           : in     Dataset;
      Epochs         : in     Positive;
      Initial_Radius : in     Data_Value)
   is
      Radius       : Data_Value;
      Decay_Factor : Data_Value;
      BMU          : Coordinate;
      Dist         : Data_Value;
      Theta        : Data_Value;
      Sample_Vec   : Vector (Data'Range(2));

      -- Accumulators structured exactly like the map layout
      type Accumulator_Map is array (Map'Range(1), Map'Range(2), Map'Range(3)) of Data_Value;
      type Denom_Map is array (Map'Range(1), Map'Range(2)) of Data_Value;

      Num : Accumulator_Map;
      Den : Denom_Map;
   begin
      if Data'Length(1) = 0 then
         raise Empty_Dataset;
      end if;
      if Data'Length(2) /= Map'Length(3) then
         raise Dimension_Mismatch;
      end if;
      if Initial_Radius <= 0.0 then
         raise Invalid_Parameters;
      end if;

      for Epoch in 1 .. Epochs loop
         Decay_Factor := Data_Value (Epoch - 1) / Data_Value (Epochs);
         Radius := Initial_Radius * Exp (-Decay_Factor * 5.0);

         Num := [others => [others => [others => 0.0]]];
         Den := [others => [others => 0.0]];

         -- Accumulate updates for all samples without modifying the map directly
         for S in Data'Range(1) loop
            Sample_Vec := Extract_Sample (Data, S);
            BMU := Find_BMU (Map, Sample_Vec);

            for X in Map'Range(1) loop
               for Y in Map'Range(2) loop
                  Dist := Grid_Distance (BMU, (X => X, Y => Y));
                  if Dist < Radius then
                     Theta := Exp (-(Dist * Dist) / (2.0 * Radius * Radius));
                     Den(X, Y) := Den(X, Y) + Theta;
                     for F in Map'Range(3) loop
                        Num(X, Y, F) := Num(X, Y, F) + Theta * Sample_Vec(F);
                     end loop;
                  end if;
               end loop;
            end loop;
         end loop;

         -- Apply aggregated updates at the end of the epoch
         for X in Map'Range(1) loop
            for Y in Map'Range(2) loop
               if Den(X, Y) > 0.0 then
                  for F in Map'Range(3) loop
                     Map(X, Y, F) := Num(X, Y, F) / Den(X, Y);
                  end loop;
               end if;
            end loop;
         end loop;
      end loop;
   end Train_Batch;

end Self_Organizing_Map;
