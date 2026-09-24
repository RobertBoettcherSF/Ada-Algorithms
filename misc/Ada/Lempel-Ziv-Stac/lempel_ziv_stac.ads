package Lempel_Ziv_Stac is
    pragma Preelaborate;

    -- Custom types for strict type safety
    type Byte is mod 256;
    type Byte_Array is array (Positive range <>) of Byte;

    -- Maximum capacity for the static bounds buffer
    Max_Buffer_Size : constant := 1024 * 1024; -- 1 MB

    type Buffer_Type is record
        Data   : Byte_Array (1 .. Max_Buffer_Size) := (others => 0);
        Length : Natural := 0;
    end record;

    -- Domain specific Exceptions
    Decompression_Error : exception;
    Buffer_Overflow     : exception;

    -- Variant 1: Compress uncompressed byte array to LZS stream
    procedure Compress (Input : in Byte_Array; Output : out Buffer_Type);

    -- Variant 2: Decompress LZS stream to original format
    procedure Decompress (Input : in Buffer_Type; Output : out Buffer_Type);

end Lempel_Ziv_Stac;
