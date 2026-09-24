--  mechanistic_interpretability.adb
--  Implementation of mechanistic interpretability variants.

package body Mechanistic_Interpretability is

   ----------------------------------------------------------------------------
   --  Linear_Transform
   ----------------------------------------------------------------------------
   function Linear_Transform (Input : Vector; Weights : Matrix; Bias : Vector) return Vector is
      Result : Vector (Bias'Range);
      Sum    : Real;
      W_Row  : Positive;
      W_Col  : Positive;
   begin
      --  Compute Input * Weights + Bias
      for I in Result'Range loop
         Sum := Bias (I);
         W_Col := Weights'First (2) + (I - Bias'First);
         
         for J in Input'Range loop
            W_Row := Weights'First (1) + (J - Input'First);
            Sum := Sum + Input (J) * Weights (W_Row, W_Col);
         end loop;
         Result (I) := Sum;
      end loop;
      
      return Result;
   end Linear_Transform;

   ----------------------------------------------------------------------------
   --  ReLU
   ----------------------------------------------------------------------------
   function ReLU (Input : Vector) return Vector is
      Result : Vector (Input'Range);
   begin
      for I in Input'Range loop
         if Input (I) > 0.0 then
            Result (I) := Input (I);
         else
            Result (I) := 0.0;
         end if;
      end loop;
      return Result;
   end ReLU;

   ----------------------------------------------------------------------------
   --  Encode_SAE
   ----------------------------------------------------------------------------
   function Encode_SAE (Activation : Vector; Encoder_Weights : Matrix; Encoder_Bias : Vector) return Vector is
   begin
      --  Dictionary learning encoder is typically: ReLU(x * W_enc + b_enc)
      return ReLU (Linear_Transform (Activation, Encoder_Weights, Encoder_Bias));
   end Encode_SAE;

   ----------------------------------------------------------------------------
   --  Decode_SAE
   ----------------------------------------------------------------------------
   function Decode_SAE (Features : Vector; Decoder_Weights : Matrix; Decoder_Bias : Vector) return Vector is
   begin
      --  Dictionary learning decoder is typically a linear transformation
      return Linear_Transform (Features, Decoder_Weights, Decoder_Bias);
   end Decode_SAE;

   ----------------------------------------------------------------------------
   --  Reconstruction_Error
   ----------------------------------------------------------------------------
   function Reconstruction_Error (Original, Reconstructed : Vector) return Real is
      Sum : Real := 0.0;
   begin
      for I in 0 .. Original'Length - 1 loop
         declare
            Diff : constant Real := Original (Original'First + I) - 
                                    Reconstructed (Reconstructed'First + I);
         begin
            Sum := Sum + (Diff * Diff);
         end;
      end loop;
      
      return Sum / Real (Original'Length);
   end Reconstruction_Error;

   ----------------------------------------------------------------------------
   --  Activation_Patch
   ----------------------------------------------------------------------------
   function Activation_Patch (Clean, Corrupted : Vector; Patch_Mask : Boolean_Mask) return Vector is
      Result : Vector (Clean'Range);
   begin
      for I in 0 .. Clean'Length - 1 loop
         declare
            Idx_Clean   : constant Positive := Clean'First + I;
            Idx_Corrupt : constant Positive := Corrupted'First + I;
            Idx_Mask    : constant Positive := Patch_Mask'First + I;
         begin
            if Patch_Mask (Idx_Mask) then
               Result (Idx_Clean) := Corrupted (Idx_Corrupt);
            else
               Result (Idx_Clean) := Clean (Idx_Clean);
            end if;
         end;
      end loop;
      return Result;
   end Activation_Patch;

   ----------------------------------------------------------------------------
   --  Is_In_Superposition
   ----------------------------------------------------------------------------
   function Is_In_Superposition (Features : Vector; Dimensions : Natural; Threshold : Real) return Boolean is
      Active_Count : Natural := 0;
   begin
      --  Superposition happens when a network uses N dimensions to represent >N features.
      for I in Features'Range loop
         if Features (I) > Threshold then
            Active_Count := Active_Count + 1;
         end if;
      end loop;
      
      return Active_Count > Dimensions;
   end Is_In_Superposition;

   ----------------------------------------------------------------------------
   --  Simulate_Induction_Head
   ----------------------------------------------------------------------------
   function Simulate_Induction_Head (Sequence : Token_Sequence) return Token_Sequence is
      Result : Token_Sequence (Sequence'Range) := (others => 0);
   begin
      --  Iterate through the sequence to predict the token that follows the current context
      for I in Sequence'First .. Sequence'Last loop
         declare
            Context_Token : constant Token_ID := Sequence (I);
            Found         : Boolean := False;
         begin
            --  Search backward for a previous occurrence of the context token.
            --  It must have a subsequent token to be useful (so J < I).
            for J in reverse Sequence'First .. I - 1 loop
               if Sequence (J) = Context_Token then
                  --  Induction pattern: output the token that historically followed it
                  Result (I) := Sequence (J + 1);
                  Found := True;
                  exit;
               end if;
            end loop;
            
            --  If no historical pattern exists, the default prediction remains 0
            if not Found then
               Result (I) := 0;
            end if;
         end;
      end loop;
      
      return Result;
   end Simulate_Induction_Head;

end Mechanistic_Interpretability;
