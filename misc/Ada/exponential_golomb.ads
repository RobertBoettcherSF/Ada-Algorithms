package Exponential_Golomb is

   -- Custom type representing a binary stream for strong typing
   subtype Bit_String is String;
   
   -- Exceptions for edge cases and corrupted streams
   Decoding_Error : exception;

   -- =========================================================
   -- Variant 1: Order-0 Unsigned (also known as ue(v))
   -- =========================================================
   function Encode_Order_0_Unsigned (Value : Natural) return Bit_String;
   function Decode_Order_0_Unsigned (Bits : Bit_String; Consumed : out Natural) return Natural;

   -- =========================================================
   -- Variant 2: Order-k Unsigned
   -- =========================================================
   function Encode_Order_K_Unsigned (Value : Natural; K : Natural) return Bit_String;
   function Decode_Order_K_Unsigned (Bits : Bit_String; K : Natural; Consumed : out Natural) return Natural;

   -- =========================================================
   -- Variant 3: Order-0 Signed (also known as se(v) in H.264)
   -- =========================================================
   function Encode_Order_0_Signed (Value : Integer) return Bit_String;
   function Decode_Order_0_Signed (Bits : Bit_String; Consumed : out Natural) return Integer;

   -- =========================================================
   -- Variant 4: Order-k Signed
   -- =========================================================
   function Encode_Order_K_Signed (Value : Integer; K : Natural) return Bit_String;
   function Decode_Order_K_Signed (Bits : Bit_String; K : Natural; Consumed : out Natural) return Integer;

end Exponential_Golomb;
