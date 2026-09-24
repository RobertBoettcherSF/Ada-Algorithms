with Ada.Numerics;
with Ada.Numerics.Elementary_Functions;
with Ada.Containers.Vectors;

package body Grovers_Algorithm is

   use Ada.Numerics.Elementary_Functions;

   --  Internal vector type for amplitude simulation
   package Float_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => Float);

   use Float_Vectors;

   -----------------------------------------------------------------
   -- Test Oracle Implementations
   -----------------------------------------------------------------
   function Oracle_Single_5 (Index : Item_Index) return Boolean is
   begin
      return Index = 5;
   end Oracle_Single_5;

   function Oracle_Single_0 (Index : Item_Index) return Boolean is
   begin
      return Index = 0;
   end Oracle_Single_0;

   function Oracle_Last_15 (Index : Item_Index) return Boolean is
   begin
      return Index = 15;
   end Oracle_Last_15;

   function Oracle_Multiple_Even (Index : Item_Index) return Boolean is
   begin
      return (Integer(Index) mod 4) = 0;
   end Oracle_Multiple_Even;

   function Oracle_None (Index : Item_Index) return Boolean is
      pragma Unreferenced (Index);
   begin
      return False;
   end Oracle_None;

   -----------------------------------------------------------------
   -- Optimal_Iterations
   -----------------------------------------------------------------
   function Optimal_Iterations 
     (N : Search_Space_Size; 
      M : Search_Space_Size := 1) return Iteration_Count is
      F_N : constant Float := Float(N);
      F_M : constant Float := Float(M);
      Val : constant Float := Float'Floor((Ada.Numerics.Pi / 4.0) * Sqrt(F_N / F_M));
      Res : constant Integer := Integer(Val);
   begin
      if Res < 0 then
         return 0;
      elsif Res > Integer(Iteration_Count'Last) then
         return Iteration_Count'Last;
      else
         return Iteration_Count(Res);
      end if;
   end Optimal_Iterations;

   -----------------------------------------------------------------
   -- Standard_Grover_Search
   -----------------------------------------------------------------
   function Standard_Grover_Search
     (N      : Search_Space_Size;
      Oracle : not null Oracle_Function) return Item_Index is
      
      Count   : constant Natural := Natural(N);
      Amps    : Vector;
      Initial : constant Float := 1.0 / Sqrt(Float(Count));
      Iters   : Iteration_Count;
      M_Count : Natural := 0;
   begin
      --  Count marked items first to determine optimal iterations
      for I in 0 .. Count - 1 loop
         if Oracle(Item_Index(I)) then
            M_Count := M_Count + 1;
         end if;
      end loop;

      if M_Count = 0 then
         raise No_Solution_Found;
      end if;

      Iters := Optimal_Iterations(N, Search_Space_Size(M_Count));

      --  Initialize uniform superposition
      Amps.Set_Length(Ada.Containers.Count_Type(Count));
      for I in 0 .. Count - 1 loop
         Amps.Replace_Element(I, Initial);
      end loop;

      --  Perform Grover iterations
      for Iter in 1 .. Integer(Iters) loop
         pragma Unreferenced(Iter);
         --  1. Oracle phase inversion for marked items
         for I in 0 .. Count - 1 loop
            if Oracle(Item_Index(I)) then
               Amps.Replace_Element(I, -Amps.Element(I));
            end if;
         end loop;

         --  2. Diffusion operator (reflection about average)
         declare
            Sum  : Float := 0.0;
            Mean : Float;
         begin
            for I in 0 .. Count - 1 loop
               Sum := Sum + Amps.Element(I);
            end loop;
            Mean := Sum / Float(Count);

            for I in 0 .. Count - 1 loop
               declare
                  Old_A : constant Float := Amps.Element(I);
               begin
                  Amps.Replace_Element(I, 2.0 * Mean - Old_A);
               end;
            end loop;
         end;
      end loop;

      --  Find index with maximum probability (amplitude squared)
      declare
         Max_Amp  : Float := -1.0;
         Best_Idx : Natural := 0;
      begin
         for I in 0 .. Count - 1 loop
            declare
               A    : constant Float := Amps.Element(I);
               Prob : constant Float := A * A;
            begin
               if Prob > Max_Amp then
                  Max_Amp := Prob;
                  Best_Idx := I;
               end if;
            end;
         end loop;
         return Item_Index(Best_Idx);
      end;
   end Standard_Grover_Search;

   -----------------------------------------------------------------
   -- Amplitude_Amplification_Search
   -----------------------------------------------------------------
   function Amplitude_Amplification_Search
     (N              : Search_Space_Size;
      Oracle         : not null Oracle_Function;
      Initial_Weight : Float) return Item_Index is
      
      Count   : constant Natural := Natural(N);
      Amps    : Vector;
      Norm    : Float;
      Iters   : Iteration_Count;
      M_Count : Natural := 0;
   begin
      for I in 0 .. Count - 1 loop
         if Oracle(Item_Index(I)) then
            M_Count := M_Count + 1;
         end if;
      end loop;

      if M_Count = 0 then
         raise No_Solution_Found;
      end if;

      Iters := Optimal_Iterations(N, Search_Space_Size(M_Count));

      --  Initialize with custom weighted superposition
      Amps.Set_Length(Ada.Containers.Count_Type(Count));
      Norm := Sqrt(Float(Count)) * Initial_Weight;
      if Norm = 0.0 then
         Norm := 1.0;
      end if;

      for I in 0 .. Count - 1 loop
         Amps.Replace_Element(I, Initial_Weight / Norm);
      end loop;

      for Iter in 1 .. Integer(Iters) loop
         pragma Unreferenced(Iter);
         for I in 0 .. Count - 1 loop
            if Oracle(Item_Index(I)) then
               Amps.Replace_Element(I, -Amps.Element(I));
            end if;
         end loop;

         declare
            Sum  : Float := 0.0;
            Mean : Float;
         begin
            for I in 0 .. Count - 1 loop
               Sum := Sum + Amps.Element(I);
            end loop;
            Mean := Sum / Float(Count);

            for I in 0 .. Count - 1 loop
               declare
                  Old_A : constant Float := Amps.Element(I);
               begin
                  Amps.Replace_Element(I, 2.0 * Mean - Old_A);
               end;
            end loop;
         end;
      end loop;

      declare
         Max_Amp  : Float := -1.0;
         Best_Idx : Natural := 0;
      begin
         for I in 0 .. Count - 1 loop
            declare
               A : constant Float := Amps.Element(I);
            begin
               if A * A > Max_Amp then
                  Max_Amp := A * A;
                  Best_Idx := I;
               end if;
            end;
         end loop;
         return Item_Index(Best_Idx);
      end;
   end Amplitude_Amplification_Search;

   -----------------------------------------------------------------
   -- Quantum_Counting_Search
   -----------------------------------------------------------------
   function Quantum_Counting_Search
     (N      : Search_Space_Size;
      Oracle : not null Oracle_Function) return Search_Space_Size is
      
      Count   : constant Natural := Natural(N);
      M_Count : Natural := 0;
   begin
      for I in 0 .. Count - 1 loop
         if Oracle(Item_Index(I)) then
            M_Count := M_Count + 1;
         end if;
      end loop;

      return Search_Space_Size(M_Count);
   end Quantum_Counting_Search;

   -----------------------------------------------------------------
   -- Multi_Solution_Grover_Search
   -----------------------------------------------------------------
   function Multi_Solution_Grover_Search
     (N          : Search_Space_Size;
      Oracle     : not null Oracle_Function;
      Expected_M : Search_Space_Size) return Item_Index is
      
      Count   : constant Natural := Natural(N);
      Amps    : Vector;
      Initial : constant Float := 1.0 / Sqrt(Float(Count));
      Iters   : Iteration_Count;
   begin
      Iters := Optimal_Iterations(N, Expected_M);

      Amps.Set_Length(Ada.Containers.Count_Type(Count));
      for I in 0 .. Count - 1 loop
         Amps.Replace_Element(I, Initial);
      end loop;

      for Iter in 1 .. Integer(Iters) loop
         pragma Unreferenced(Iter);
         for I in 0 .. Count - 1 loop
            if Oracle(Item_Index(I)) then
               Amps.Replace_Element(I, -Amps.Element(I));
            end if;
         end loop;

         declare
            Sum  : Float := 0.0;
            Mean : Float;
         begin
            for I in 0 .. Count - 1 loop
               Sum := Sum + Amps.Element(I);
            end loop;
            Mean := Sum / Float(Count);

            for I in 0 .. Count - 1 loop
               declare
                  Old_A : constant Float := Amps.Element(I);
               begin
                  Amps.Replace_Element(I, 2.0 * Mean - Old_A);
               end;
            end loop;
         end;
      end loop;

      declare
         Max_Amp  : Float := -1.0;
         Best_Idx : Natural := 0;
      begin
         for I in 0 .. Count - 1 loop
            declare
               A : constant Float := Amps.Element(I);
            begin
               if A * A > Max_Amp then
                  Max_Amp := A * A;
                  Best_Idx := I;
               end if;
            end;
         end loop;
         return Item_Index(Best_Idx);
      end;
   end Multi_Solution_Grover_Search;

end Grovers_Algorithm;
