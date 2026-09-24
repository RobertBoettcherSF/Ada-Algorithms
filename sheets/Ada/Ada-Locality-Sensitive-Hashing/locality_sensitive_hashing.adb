with Ada.Unchecked_Conversion;

package body Locality_Sensitive_Hashing is

   -----------------------------------------------------------------------------
   --  Helper Functions
   -----------------------------------------------------------------------------
   
   --  Internal Hash for MinHash combining an element with a seed
   function Hash_Int (Value : Integer; Seed : Hash_Value) return Hash_Value is
      function To_Unsigned is new Ada.Unchecked_Conversion (Integer, Hash_Value);
      U : constant Hash_Value := To_Unsigned (Value);
      M : constant Hash_Value := 16#5BD1_E995#;
      K : Hash_Value := U * M;
   begin
      --  Simple mixing logic inspired by MurmurHash
      K := K xor (K / 16#100_0000#); 
      K := K * M;
      return K xor Seed;
   end Hash_Int;

   -----------------------------------------------------------------------------
   --  Variant 1: Bit Sampling LSH
   -----------------------------------------------------------------------------
   
   function Bit_Sampling_Hash
     (Data    : Bit_Vector;
      Indices : Index_Array) return Hash_Value
   is
      Result : Hash_Value := 0;
   begin
      if Indices'Length = 0 or else Data'Length = 0 then
         raise Empty_Input;
      end if;

      if Indices'Length > 32 then
         raise Dimension_Mismatch;
      end if;

      for I in Indices'Range loop
         if Indices (I) < Data'First or else Indices (I) > Data'Last then
            raise Invalid_Index;
         end if;
         
         --  Shift left by 1 and append the sampled bit
         Result := Result * 2;
         if Data (Indices (I)) then
            Result := Result + 1;
         end if;
      end loop;

      return Result;
   end Bit_Sampling_Hash;

   -----------------------------------------------------------------------------
   --  Variant 2: MinHash LSH
   -----------------------------------------------------------------------------
   
   function Min_Hash
     (Data : Integer_Array;
      Seed : Hash_Value) return Hash_Value
   is
      Current_Min : Hash_Value := Hash_Value'Last;
      H           : Hash_Value;
   begin
      if Data'Length = 0 then
         raise Empty_Input;
      end if;

      for I in Data'Range loop
         H := Hash_Int (Data (I), Seed);
         if H < Current_Min then
            Current_Min := H;
         end if;
      end loop;

      return Current_Min;
   end Min_Hash;

   function Min_Hash_Signature
     (Data  : Integer_Array;
      Seeds : Hash_Array) return Hash_Array
   is
      Result : Hash_Array (Seeds'Range);
   begin
      if Data'Length = 0 or else Seeds'Length = 0 then
         raise Empty_Input;
      end if;

      for I in Seeds'Range loop
         Result (I) := Min_Hash (Data, Seeds (I));
      end loop;

      return Result;
   end Min_Hash_Signature;

   function Estimate_Jaccard_Similarity
     (Sig_A, Sig_B : Hash_Array) return Long_Float
   is
      Matches  : Natural := 0;
      Offset_B : Integer;
   begin
      if Sig_A'Length = 0 or else Sig_B'Length = 0 then
         raise Empty_Input;
      end if;

      if Sig_A'Length /= Sig_B'Length then
         raise Dimension_Mismatch;
      end if;

      Offset_B := Sig_B'First - Sig_A'First;
      for I in Sig_A'Range loop
         if Sig_A (I) = Sig_B (I + Offset_B) then
            Matches := Matches + 1;
         end if;
      end loop;

      return Long_Float (Matches) / Long_Float (Sig_A'Length);
   end Estimate_Jaccard_Similarity;

   -----------------------------------------------------------------------------
   --  Variant 3: Random Projection LSH
   -----------------------------------------------------------------------------
   
   function Random_Projection_Hash
     (Data       : Float_Vector;
      Hyperplane : Float_Vector) return Boolean
   is
      Dot_Product : Long_Float := 0.0;
      Offset_H    : Integer;
   begin
      if Data'Length = 0 or else Hyperplane'Length = 0 then
         raise Empty_Input;
      end if;

      if Data'Length /= Hyperplane'Length then
         raise Dimension_Mismatch;
      end if;

      Offset_H := Hyperplane'First - Data'First;
      for I in Data'Range loop
         Dot_Product := Dot_Product + (Data (I) * Hyperplane (I + Offset_H));
      end loop;

      return Dot_Product > 0.0;
   end Random_Projection_Hash;

   function Cosine_Signature
     (Data        : Float_Vector;
      Hyperplanes : Float_Matrix) return Bit_Vector
   is
      Result : Bit_Vector (Hyperplanes'Range (1));
   begin
      if Data'Length = 0 or else Hyperplanes'Length (1) = 0 or else Hyperplanes'Length (2) = 0 then
         raise Empty_Input;
      end if;

      if Data'Length /= Hyperplanes'Length (2) then
         raise Dimension_Mismatch;
      end if;

      for I in Hyperplanes'Range (1) loop
         declare
            Row : Float_Vector (Hyperplanes'Range (2));
         begin
            for J in Hyperplanes'Range (2) loop
               Row (J) := Hyperplanes (I, J);
            end loop;
            Result (I) := Random_Projection_Hash (Data, Row);
         end;
      end loop;

      return Result;
   end Cosine_Signature;

end Locality_Sensitive_Hashing;
