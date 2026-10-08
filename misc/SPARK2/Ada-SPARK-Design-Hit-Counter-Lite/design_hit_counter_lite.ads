pragma Ada_2022;
package Design_Hit_Counter_Lite with SPARK_Mode => On is
   Bucket_Count : constant := 4;
   Bucket_Capacity : constant := 100;
   subtype Bucket is Positive range 1 .. Bucket_Count;
   subtype Hits is Natural range 0 .. Bucket_Capacity;
   type Counter is private;
   function Empty return Counter with Global => null;
   procedure Hit (C : in out Counter; B : Bucket)
     with Global => null, Pre => Read (C, B) < Bucket_Capacity;
   function Read (C : Counter; B : Bucket) return Hits with Global => null;
   function Total (C : Counter) return Natural with Global => null;
private
   type Hit_Array is array (Bucket) of Hits;
   type Counter is record Bucket_Hits : Hit_Array := (others => 0); end record;
end Design_Hit_Counter_Lite;
