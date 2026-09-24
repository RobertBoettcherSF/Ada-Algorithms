-- audio_compression.ads
-- Package specification for Audio Data Compression algorithms.
-- Implements Mu-law, A-law, and Differential Pulse-Code Modulation (DPCM).

package Audio_Compression is
   pragma Preelaborate;

   -- =========================================================================
   -- STRONG TYPING DEFINITIONS
   -- =========================================================================
   -- Using custom types to represent specific audio bit-depths
   type PCM_16 is range -32768 .. 32767;
   type PCM_8  is range -128 .. 127;

   -- Unconstrained arrays for dynamic buffer processing
   type Buffer_16 is array (Positive range <>) of PCM_16;
   type Buffer_8  is array (Positive range <>) of PCM_8;

   -- Constants for companding algorithms
   Mu_Value : constant Float := 255.0;
   A_Value  : constant Float := 87.6;

   -- =========================================================================
   -- VARIANT 1: MU-LAW COMPANDING (Used in US/Japan telecommunications)
   -- A lossy compression algorithm that reduces dynamic range.
   -- =========================================================================
   function Encode_Mu_Law (Sample : PCM_16) return PCM_8;
   function Decode_Mu_Law (Sample : PCM_8) return PCM_16;

   -- =========================================================================
   -- VARIANT 2: A-LAW COMPANDING (Used in Europe/Rest of World)
   -- A slightly different logarithmic curve for lossy compression.
   -- =========================================================================
   function Encode_A_Law (Sample : PCM_16) return PCM_8;
   function Decode_A_Law (Sample : PCM_8) return PCM_16;

   -- =========================================================================
   -- VARIANT 3: DIFFERENTIAL PULSE-CODE MODULATION (DPCM)
   -- The predictive foundation for lossless codecs (FLAC/ALAC) and some lossy.
   -- Stores the difference between consecutive samples.
   -- =========================================================================
   function Encode_DPCM (Input : Buffer_16) return Buffer_16;
   function Decode_DPCM (Input : Buffer_16) return Buffer_16;

end Audio_Compression;
