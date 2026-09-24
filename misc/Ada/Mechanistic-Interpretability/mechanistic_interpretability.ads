pragma Assertion_Policy (Pre => Check, Post => Check);

--  mechanistic_interpretability.ads
--  Core algorithmic components modeling Mechanistic Interpretability,
--  including Sparse Autoencoders (Dictionary Learning), Activation Patching,
--  and Circuit Analysis (Induction Heads).

package Mechanistic_Interpretability is

   --  Strong typing for all domains as required
   type Real is new Float;
   type Token_ID is new Natural;
   
   --  Standard array types used across the neural models
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;
   type Boolean_Mask is array (Positive range <>) of Boolean;
   type Token_Sequence is array (Positive range <>) of Token_ID;

   --  Exceptions for edge cases not caught by contracts
   Dimension_Mismatch : exception;
   Invalid_Input      : exception;

   --  ========================================================================
   --  Variant 1: Sparse Autoencoder (SAE) / Dictionary Learning
   --  Used to map dense network activations into a higher-dimensional, 
   --  interpretable sparse feature space.
   --  ========================================================================

   --  Helper: Matrix-Vector multiplication with bias
   function Linear_Transform (Input : Vector; Weights : Matrix; Bias : Vector) return Vector
     with Pre => Input'Length = Weights'Length (1) 
                 and then Bias'Length = Weights'Length (2),
          Post => Linear_Transform'Result'Length = Bias'Length;

   --  Helper: Rectified Linear Unit activation
   function ReLU (Input : Vector) return Vector
     with Post => ReLU'Result'Length = Input'Length;

   --  SAE Encode: Maps neural activations to interpretable sparse features
   function Encode_SAE (Activation : Vector; Encoder_Weights : Matrix; Encoder_Bias : Vector) return Vector
     with Pre => Activation'Length = Encoder_Weights'Length (1) 
                 and then Encoder_Bias'Length = Encoder_Weights'Length (2),
          Post => Encode_SAE'Result'Length = Encoder_Bias'Length;

   --  SAE Decode: Reconstructs neural activations from sparse features
   function Decode_SAE (Features : Vector; Decoder_Weights : Matrix; Decoder_Bias : Vector) return Vector
     with Pre => Features'Length = Decoder_Weights'Length (1) 
                 and then Decoder_Bias'Length = Decoder_Weights'Length (2),
          Post => Decode_SAE'Result'Length = Decoder_Bias'Length;

   --  Evaluates dictionary learning fidelity via Mean Squared Error (MSE)
   function Reconstruction_Error (Original, Reconstructed : Vector) return Real
     with Pre => Original'Length = Reconstructed'Length and then Original'Length > 0;

   --  ========================================================================
   --  Variant 2: Activation Patching / Causal Tracing
   --  Replaces a subset of a network's hidden activations (clean) with 
   --  counterfactual ones (corrupted) to isolate functional components.
   --  ========================================================================

   function Activation_Patch (Clean, Corrupted : Vector; Patch_Mask : Boolean_Mask) return Vector
     with Pre => Clean'Length = Corrupted'Length 
                 and then Clean'Length = Patch_Mask'Length,
          Post => Activation_Patch'Result'Length = Clean'Length;

   --  ========================================================================
   --  Variant 3: Polysemanticity & Superposition Analysis
   --  Identifies if a network represents more orthogonal features than it has 
   --  dimensions by counting features active above a threshold.
   --  ========================================================================

   function Is_In_Superposition (Features : Vector; Dimensions : Natural; Threshold : Real) return Boolean
     with Pre => Features'Length > 0;

   --  ========================================================================
   --  Variant 4: Circuit Analysis - Induction Heads
   --  A minimalist simulation of an attention circuit that predicts the next 
   --  token by finding earlier occurrences of the current token.
   --  ========================================================================

   function Simulate_Induction_Head (Sequence : Token_Sequence) return Token_Sequence
     with Post => Simulate_Induction_Head'Result'Length = Sequence'Length;

end Mechanistic_Interpretability;
