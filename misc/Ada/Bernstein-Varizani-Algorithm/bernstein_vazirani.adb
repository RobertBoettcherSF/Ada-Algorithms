with Ada.Numerics.Elementary_Functions;
with Interfaces;

package body Bernstein_Vazirani is

   function To_String (B : Bit_String) return String is
      S     : String (1 .. B'Length);
      Index : Positive := 1;
   begin
      for I in B'Range loop
         if B (I) = 1 then
            S (Index) := '1';
         else
            S (Index) := '0';
         end if;
         Index := Index + 1;
      end loop;
      return S;
   end To_String;

   function From_String (S : String) return Bit_String is
      B     : Bit_String (1 .. S'Length);
      Index : Positive := 1;
   begin
      for I in S'Range loop
         if S (I) = '1' then
            B (Index) := 1;
         elsif S (I) = '0' then
            B (Index) := 0;
         else
            raise Constraint_Error with "Invalid character in bit string";
         end if;
         Index := Index + 1;
      end loop;
      return B;
   end From_String;

   function Make_Oracle (Secret : Bit_String) return Secret_Oracle is
      Normalized_Secret : Bit_String (1 .. Secret'Length);
      Index             : Positive := 1;
   begin
      for I in Secret'Range loop
         Normalized_Secret (Index) := Secret (I);
         Index := Index + 1;
      end loop;
      return Secret_Oracle'(N => Secret'Length, Secret => Normalized_Secret);
   end Make_Oracle;

   overriding function Query (O : Secret_Oracle; X : Bit_String) return Bit is
      Result : Bit := 0;
   begin
      if X'Length /= O.N then
         raise Constraint_Error with "Oracle queried with wrong bit string length";
      end if;
      
      -- Bernstein-Vazirani Oracle evaluates the bitwise dot product mod 2
      for I in X'Range loop
         Result := Result xor (X (I) and O.Secret (I - X'First + 1));
      end loop;
      return Result;
   end Query;

   function Solve_Classical (N : Positive; Oracle : Oracle_Interface'Class) return Bit_String is
      Result    : Bit_String (1 .. N) := [others => 0];
      Query_Str : Bit_String (1 .. N);
   begin
      -- To find the secret, we query the oracle with strings containing a single '1'
      -- at each position to reveal the secret bit-by-bit.
      for I in 1 .. N loop
         Query_Str := [others => 0];
         Query_Str (I) := 1;
         Result (I) := Oracle.Query (Query_Str);
      end loop;
      return Result;
   end Solve_Classical;

   function Solve_Quantum_Simulated (N : Positive; Oracle : Oracle_Interface'Class) return Bit_String is
      Num_Qubits : constant Positive := N + 1;
      Num_States : constant Natural  := 2 ** Num_Qubits;
      
      type Amplitude_Array is array (Natural range <>) of Float;
      State      : Amplitude_Array (0 .. Num_States - 1) := [others => 0.0];
      Inv_Sqrt_2 : constant Float := 1.0 / Ada.Numerics.Elementary_Functions.Sqrt (2.0);

      -- Helper to extract the input bits (x) corresponding to an integer state
      function To_Bit_String (Val : Natural) return Bit_String is
         Result : Bit_String (1 .. N);
         Temp   : Natural := Val;
      begin
         for I in reverse 1 .. N loop
            Result (I) := Bit (Temp mod 2);
            Temp := Temp / 2;
         end loop;
         return Result;
      end To_Bit_String;

      -- Applies the Hadamard gate to a specific qubit Q across the entire state vector
      procedure Apply_Hadamard (S : in out Amplitude_Array; Q : Natural) is
         use type Interfaces.Unsigned_32;
         Bit_Mask : constant Interfaces.Unsigned_32 := 2 ** Q;
         I_Un     : Interfaces.Unsigned_32;
         I0, I1   : Natural;
         A0, A1   : Float;
      begin
         for I in S'Range loop
            I_Un := Interfaces.Unsigned_32 (I);
            if (I_Un and Bit_Mask) = 0 then
               I0 := I;
               I1 := Natural (I_Un or Bit_Mask);
               A0 := S (I0);
               A1 := S (I1);
               S (I0) := (A0 + A1) * Inv_Sqrt_2;
               S (I1) := (A0 - A1) * Inv_Sqrt_2;
            end if;
         end loop;
      end Apply_Hadamard;
      
      Idx_0, Idx_1 : Natural;
      Temp_Amp     : Float;
      Max_Prob     : Float := -1.0;
      Best_X       : Natural := 0;
      Prob         : Float;
   begin
      -- Step 1: Initialization. 
      -- The register |x> is |0...0>, and the ancillary |y> is |1>.
      -- Index layout: Bits N down to 1 represent |x>, bit 0 represents |y>. 
      -- Thus x=0, y=1 corresponds to integer state 1.
      State (1) := 1.0;

      -- Step 2: Apply Hadamard to all N+1 qubits
      for Q in 0 .. Num_Qubits - 1 loop
         Apply_Hadamard (State, Q);
      end loop;

      -- Step 3: Apply the Quantum Oracle U_f
      -- It maps |x, y> to |x, y XOR f(x)>
      for X_Int in 0 .. 2**N - 1 loop
         if Oracle.Query (To_Bit_String (X_Int)) = 1 then
            -- Swap the amplitudes of |x, 0> and |x, 1>
            Idx_0 := X_Int * 2;
            Idx_1 := X_Int * 2 + 1;
            Temp_Amp := State (Idx_0);
            State (Idx_0) := State (Idx_1);
            State (Idx_1) := Temp_Amp;
         end if;
      end loop;

      -- Step 4: Apply Hadamard to the first N qubits (the |x> register)
      for Q in 1 .. Num_Qubits - 1 loop
         Apply_Hadamard (State, Q);
      end loop;

      -- Step 5: Measurement. Find the state |x> with maximum probability.
      for X_Int in 0 .. 2**N - 1 loop
         Prob := State (X_Int * 2)**2 + State (X_Int * 2 + 1)**2;
         if Prob > Max_Prob then
            Max_Prob := Prob;
            Best_X := X_Int;
         end if;
      end loop;

      return To_Bit_String (Best_X);
   end Solve_Quantum_Simulated;

end Bernstein_Vazirani;
