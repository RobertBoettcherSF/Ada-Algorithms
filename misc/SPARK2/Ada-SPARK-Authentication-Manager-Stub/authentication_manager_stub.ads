pragma SPARK_Mode (On);

package Authentication_Manager_Stub is
   subtype Time is Integer range 0 .. 100_000;
   subtype Token_Count is Natural range 0 .. 32;
   subtype Expiration is Time;
   type Expiration_Array is array (Positive range 1 .. 32) of Expiration;

   function Is_Valid (Expires_At : Expiration; Now : Time) return Boolean
     with Global => null;

   function Count_Unexpired
     (Expires : Expiration_Array;
      Length  : Token_Count;
      Now     : Time) return Token_Count
     with Pre => Length <= Expires'Length,
          Global => null;
end Authentication_Manager_Stub;
