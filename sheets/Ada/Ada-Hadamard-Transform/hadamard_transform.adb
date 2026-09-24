with Ada.Numerics.Elementary_Functions;

package body Hadamard_Transform is

   --------------------
   -- Is_Power_Of_Two --
   --------------------
   function Is_Power_Of_Two (N : Natural) return Boolean is
      Temp : Natural := N;
   begin
      if N = 0 then
         return False;
      end if;
      while Temp > 1 and then Temp mod 2 = 0 loop
         Temp := Temp / 2;
      end loop;
      return Temp = 1;
   end Is_Power_Of_Two;

   -----------------
   -- Bit_Reverse --
   -----------------
   function Bit_Reverse (Val : Natural; Bits : Natural) return Natural is
      Res : Natural := 0;
      V   : Natural := Val;
   begin
      for I in 1 .. Bits loop
         Res := (Res * 2) + (V mod 2);
         V   := V / 2;
      end loop;
      return Res;
   end Bit_Reverse;

   -----------------------------------
   -- Fast_Walsh_Hadamard_Transform --
   -----------------------------------
   function Fast_Walsh_Hadamard_Transform (Input : Vector_Integer) return Vector_Integer is
      Result : Vector_Integer := Input;
      N      : constant Natural := Input'Length;
      Step   : Positive := 1;
   begin
      if N = 0 then
         raise Null_Input_Exception;
      end if;
      if not Is_Power_Of_Two (N) then
         raise Invalid_Length_Exception;
      end if;

      -- Iterative butterfly FWHT algorithm
      while Step < N loop
         declare
            I : Positive := Result'First;
         begin
            while I <= Result'Last loop
               for J in 0 .. Step - 1 loop
                  declare
                     Idx1 : constant Positive := I + J;
                     Idx2 : constant Positive := I + J + Step;
                     U    : constant Element_Integer := Result (Idx1);
                     V    : constant Element_Integer := Result (Idx2);
                  begin
                     Result (Idx1) := U + V;
                     Result (Idx2) := U - V;
                  end;
               end loop;
               I := I + 2 * Step;
            end loop;
         end;
         Step := Step * 2;
      end loop;

      return Result;
   end Fast_Walsh_Hadamard_Transform;

   ---------------------
   -- Normalized_FWHT --
   ---------------------
   function Normalized_FWHT (Input : Vector_Float) return Vector_Float is
      Result : Vector_Float := Input;
      N      : constant Natural := Input'Length;
      Step   : Positive := 1;
      Scale  : Element_Float;
   begin
      if N = 0 then
         raise Null_Input_Exception;
      end if;
      if not Is_Power_Of_Two (N) then
         raise Invalid_Length_Exception;
      end if;

      -- Forward butterfly computation
      while Step < N loop
         declare
            I : Positive := Result'First;
         begin
            while I <= Result'Last loop
               for J in 0 .. Step - 1 loop
                  declare
                     Idx1 : constant Positive := I + J;
                     Idx2 : constant Positive := I + J + Step;
                     U    : constant Element_Float := Result (Idx1);
                     V    : constant Element_Float := Result (Idx2);
                  begin
                     Result (Idx1) := U + V;
                     Result (Idx2) := U - V;
                  end;
               end loop;
               I := I + 2 * Step;
            end loop;
         end;
         Step := Step * 2;
      end loop;

      -- Apply normalization factor 1 / sqrt(N)
      Scale := Element_Float (1.0 / Ada.Numerics.Elementary_Functions.Sqrt (Float (N)));
      for E of Result loop
         E := E * Scale;
      end loop;

      return Result;
   end Normalized_FWHT;

   ------------------
   -- Inverse_FWHT --
   ------------------
   function Inverse_FWHT (Input : Vector_Float) return Vector_Float is
      -- For orthogonal normalized Hadamard transform, inverse equals forward transform.
   begin
      if Input'Length = 0 then
         raise Null_Input_Exception;
      end if;
      if not Is_Power_Of_Two (Input'Length) then
         raise Invalid_Length_Exception;
      end if;

      return Normalized_FWHT (Input);
   end Inverse_FWHT;

   -----------------------------
   -- Sequency_Ordered_FWHT --
   -----------------------------
   function Sequency_Ordered_FWHT (Input : Vector_Integer) return Vector_Integer is
      Dyadic : constant Vector_Integer := Fast_Walsh_Hadamard_Transform (Input);
      Result : Vector_Integer := Dyadic;
      N      : constant Natural := Input'Length;
      M      : Natural := 0;
      Temp_N : Natural := N;
   begin
      if N = 0 then
         raise Null_Input_Exception;
      end if;
      if not Is_Power_Of_Two (N) then
         raise Invalid_Length_Exception;
      end if;

      while Temp_N > 1 loop
         M      := M + 1;
         Temp_N := Temp_N / 2;
      end loop;

      -- Permute dyadic output using bit-reversal to obtain sequency (Walsh) ordering
      for I in 0 .. N - 1 loop
         declare
            Rev_I : constant Natural := Bit_Reverse (I, M);
         begin
            if Rev_I > I then
               declare
                  Temp_Val : constant Element_Integer := Result (I + Result'First);
               begin
                  Result (I + Result'First) := Result (Rev_I + Result'First);
                  Result (Rev_I + Result'First) := Temp_Val;
               end;
            end if;
         end;
      end loop;

      return Result;
   end Sequency_Ordered_FWHT;

end Hadamard_Transform;
