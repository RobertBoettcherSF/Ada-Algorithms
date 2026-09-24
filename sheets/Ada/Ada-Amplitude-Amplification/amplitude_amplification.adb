with Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Amplitude_Amplification is

   -- Tolerance for floating-point comparisons when checking vector normalization
   Tolerance : constant Amplitude := 1.0e-4;

   function Is_Normalized (State : State_Vector) return Boolean is
      Sum : Amplitude := 0.0;
   begin
      for I in State'Range loop
         Sum := Sum + (State (I) * State (I));
      end loop;
      return abs (Sum - 1.0) <= Tolerance;
   end Is_Normalized;

   function Inner_Product (Left, Right : State_Vector) return Amplitude is
      Sum : Amplitude := 0.0;
   begin
      for I in Left'Range loop
         Sum := Sum + (Left (I) * Right (I));
      end loop;
      return Sum;
   end Inner_Product;

   procedure Apply_Oracle (State : in out State_Vector; Oracle : not null access function (Index : State_Index) return Boolean) is
   begin
      for I in State'Range loop
         -- The oracle marks solutions by flipping their phase (multiplying amplitude by -1)
         if Oracle (I) then
            State (I) := -State (I);
         end if;
      end loop;
   end Apply_Oracle;

   procedure Apply_Diffusion (State : in out State_Vector; Initial_State : State_Vector) is
      -- The projection onto the initial state
      C : constant Amplitude := Inner_Product (State, Initial_State);
   begin
      -- Applies the diffusion operator D = 2|initial><initial| - I
      -- This efficiently reflects the current state about the initial state
      for I in State'Range loop
         State (I) := 2.0 * C * Initial_State (I) - State (I);
      end loop;
   end Apply_Diffusion;

   function Standard_Amplification
     (Initial_State : State_Vector;
      Oracle        : not null access function (Index : State_Index) return Boolean;
      Iterations    : Natural) return State_Vector
   is
      Current_State : State_Vector := Initial_State;
   begin
      for I in 1 .. Iterations loop
         Apply_Oracle (Current_State, Oracle);
         Apply_Diffusion (Current_State, Initial_State);
      end loop;
      return Current_State;
   end Standard_Amplification;

   function Optimal_Iterations (Success_Probability : Amplitude) return Natural is
      use Ada.Numerics.Long_Elementary_Functions;
      Theta : Amplitude;
      Pi    : constant Amplitude := 3.14159_26535_89793_23846;
   begin
      -- If the probability is already perfect, no iterations are needed
      if Success_Probability >= 1.0 then
         return 0;
      end if;
      
      -- Calculate the rotation angle and return the optimal Grover iteration count
      Theta := Amplitude (Arcsin (Sqrt (Long_Float (Success_Probability))));
      return Natural (Long_Float'Floor (Long_Float (Pi / (4.0 * Theta))));
   end Optimal_Iterations;

   function Exponential_Search
     (Initial_State : State_Vector;
      Oracle        : not null access function (Index : State_Index) return Boolean;
      Max_Steps     : Natural := 1000) return State_Index
   is
      M            : Long_Float := 1.0;
      Growth_Ratio : constant Long_Float := 1.2; -- Standard Brassard 6/5 ratio
      Gen          : Ada.Numerics.Float_Random.Generator;
      Limit        : Natural;
      Steps        : Natural;
      State        : State_Vector (Initial_State'Range);
      Found        : State_Index;
      Current_Step : Natural := 1;
   begin
      Ada.Numerics.Float_Random.Reset (Gen);
      
      while Current_Step <= Max_Steps loop
         Limit := Natural (Long_Float'Floor (M));
         
         if Limit = 0 then
            Steps := 0;
         else
            -- Pick a random integer number of steps between 0 and Limit
            Steps := Natural (Float'Floor (Float (Limit + 1) * Ada.Numerics.Float_Random.Random (Gen)));
            if Steps > Limit then
               Steps := Limit;
            end if;
         end if;

         -- Apply amplification with the randomly chosen number of steps
         State := Standard_Amplification (Initial_State, Oracle, Steps);
         
         -- Measure the resulting state
         Found := Measure_Most_Likely (State);

         -- Check if the measured state is a valid solution
         if Oracle (Found) then
            return Found;
         end if;

         -- Increase the maximum number of iterations exponentially
         M := M * Growth_Ratio;
         if M > 1.0E6 then
            M := 1.0E6; -- Cap to prevent integer overflow on limit cast
         end if;
         
         Current_Step := Current_Step + 1;
      end loop;

      -- Raised if Max_Steps is reached without measuring a valid solution
      raise No_Solution_Error;
   end Exponential_Search;

   function Uniform_Superposition (First, Last : State_Index) return State_Vector is
      Length : constant Natural := Natural (Last - First) + 1;
      Amp    : constant Amplitude := Amplitude (1.0 / Ada.Numerics.Long_Elementary_Functions.Sqrt (Long_Float (Length)));
      Result : State_Vector (First .. Last);
   begin
      for I in Result'Range loop
         Result (I) := Amp;
      end loop;
      return Result;
   end Uniform_Superposition;

   function Measure_Most_Likely (State : State_Vector) return State_Index is
      Max_Prob : Amplitude := -1.0;
      Best_Idx : State_Index := State'First;
      Prob     : Amplitude;
   begin
      for I in State'Range loop
         -- Measurement depends on the probability (amplitude squared)
         Prob := State (I) * State (I);
         if Prob > Max_Prob then
            Max_Prob := Prob;
            Best_Idx := I;
         end if;
      end loop;
      return Best_Idx;
   end Measure_Most_Likely;

end Amplitude_Amplification;
